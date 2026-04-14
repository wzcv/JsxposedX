#include "memory_tool_scanner.h"

#include <algorithm>

namespace memory_tool {

namespace {

constexpr size_t kChunkSize = 1024 * 1024;
constexpr size_t kNextScanBatchSize = 256;
constexpr size_t kProgressEntryInterval = 2048;
constexpr uint64_t kProgressByteInterval = 4ULL * 1024ULL * 1024ULL;

size_t ResolveStep(SearchValueType type) {
    switch (type) {
        case SearchValueType::kI8:
        case SearchValueType::kBytes:
            return 1;
        case SearchValueType::kI16:
            return 2;
        case SearchValueType::kI32:
        case SearchValueType::kF32:
            return 4;
        case SearchValueType::kI64:
        case SearchValueType::kF64:
            return 8;
    }
    return 1;
}

}  // namespace

std::vector<SearchResultEntry> FirstScan(ProcessMemoryReader* reader,
                                         const std::vector<MemoryRegion>& regions,
                                         const std::vector<uint8_t>& pattern,
                                         SearchValueType type,
                                         const SearchProgressCallback& progress_callback) {
    std::vector<SearchResultEntry> results;
    if (reader == nullptr || pattern.empty()) {
        return results;
    }

    const size_t step = ResolveStep(type);
    const size_t overlap = pattern.size() > 1 ? pattern.size() - 1 : 0;
    SearchScanProgress progress;
    uint64_t last_reported_byte_count = 0;
    progress.total_region_count = regions.size();
    for (const MemoryRegion& region : regions) {
        progress.total_byte_count += region.size;
    }
    if (progress_callback && !progress_callback(progress)) {
        return results;
    }

    for (const MemoryRegion& region : regions) {
        for (uint64_t cursor = region.start_address; cursor < region.end_address;) {
            const size_t remaining = static_cast<size_t>(region.end_address - cursor);
            const size_t base_read_size = std::min(kChunkSize, remaining);
            const size_t read_size = std::min(remaining, base_read_size + overlap);

            std::vector<uint8_t> buffer;
            if (!reader->Read(cursor, read_size, &buffer) || buffer.size() < pattern.size()) {
                cursor += base_read_size;
                continue;
            }

            const size_t scan_limit = std::min(base_read_size, buffer.size() - pattern.size() + 1);
            for (size_t index = 0; index < scan_limit; index += step) {
                if (!std::equal(pattern.begin(),
                                pattern.end(),
                                buffer.begin() + static_cast<std::ptrdiff_t>(index))) {
                    continue;
                }

                SearchResultEntry entry;
                entry.address = cursor + index;
                entry.region_start = region.start_address;
                results.push_back(std::move(entry));
            }

            progress.processed_byte_count += base_read_size;
            progress.result_count = results.size();
            const bool should_report =
                (progress.processed_byte_count - last_reported_byte_count) >= kProgressByteInterval;
            if (should_report && progress_callback && !progress_callback(progress)) {
                return results;
            }
            if (should_report) {
                last_reported_byte_count = progress.processed_byte_count;
            }
            cursor += base_read_size;
        }

        ++progress.processed_region_count;
        progress.result_count = results.size();
        if (progress_callback && !progress_callback(progress)) {
            return results;
        }
    }

    return results;
}

std::vector<SearchResultEntry> NextScan(ProcessMemoryReader* reader,
                                        const std::vector<SearchResultEntry>& previous_results,
                                        const std::vector<uint8_t>& pattern,
                                        const SearchProgressCallback& progress_callback) {
    std::vector<SearchResultEntry> results;
    if (reader == nullptr || pattern.empty()) {
        return results;
    }

    SearchScanProgress progress;
    size_t last_reported_entry_count = 0;
    progress.total_entry_count = previous_results.size();
    progress.total_byte_count =
        static_cast<uint64_t>(previous_results.size()) * static_cast<uint64_t>(pattern.size());
    if (progress_callback && !progress_callback(progress)) {
        return results;
    }

    for (size_t start = 0; start < previous_results.size(); start += kNextScanBatchSize) {
        const size_t count = std::min(kNextScanBatchSize, previous_results.size() - start);
        std::vector<uint64_t> addresses;
        addresses.reserve(count);
        for (size_t index = 0; index < count; ++index) {
            addresses.push_back(previous_results[start + index].address);
        }

        std::vector<std::vector<uint8_t>> buffers;
        reader->ReadMany(addresses, pattern.size(), &buffers);
        for (size_t index = 0; index < count; ++index) {
            const SearchResultEntry& candidate = previous_results[start + index];
            const std::vector<uint8_t>& current = buffers[index];
            if (current.size() == pattern.size() &&
                std::equal(pattern.begin(), pattern.end(), current.begin())) {
                SearchResultEntry entry = candidate;
                results.push_back(std::move(entry));
            }
        }

        progress.processed_entry_count += count;
        progress.processed_byte_count += static_cast<uint64_t>(count) *
                                         static_cast<uint64_t>(pattern.size());
        progress.result_count = results.size();
        const bool should_report =
            (progress.processed_entry_count - last_reported_entry_count) >= kProgressEntryInterval;
        if (should_report && progress_callback && !progress_callback(progress)) {
            return results;
        }
        if (should_report) {
            last_reported_entry_count = progress.processed_entry_count;
        }
    }

    if (progress_callback) {
        progress_callback(progress);
    }
    return results;
}

}  // namespace memory_tool
