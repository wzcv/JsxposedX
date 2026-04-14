#include "memory_tool_reader.h"

#include <cerrno>
#include <fcntl.h>
#include <signal.h>
#include <string>
#include <sys/uio.h>
#include <unistd.h>

namespace memory_tool {

namespace {

constexpr size_t kReadManyBatchSize = 128;

}  // namespace

ProcessMemoryReader::ProcessMemoryReader(int pid) : pid_(pid) {
    mem_fd_ = open(("/proc/" + std::to_string(pid_) + "/mem").c_str(), O_RDONLY | O_CLOEXEC);
}

ProcessMemoryReader::~ProcessMemoryReader() {
    if (mem_fd_ >= 0) {
        close(mem_fd_);
    }
}

bool ProcessMemoryReader::Read(uint64_t address,
                               size_t size,
                               std::vector<uint8_t>* buffer) const {
    if (buffer == nullptr || size == 0) {
        return false;
    }

    buffer->clear();
    buffer->resize(size);
    if (ReadWithProcessVmReadv(address, size, buffer)) {
        return true;
    }
    if (ReadWithPread(address, size, buffer)) {
        return true;
    }
    buffer->clear();
    return false;
}

bool ProcessMemoryReader::ReadMany(const std::vector<uint64_t>& addresses,
                                   size_t size,
                                   std::vector<std::vector<uint8_t>>* buffers) const {
    if (buffers == nullptr || size == 0) {
        return false;
    }

    buffers->clear();
    buffers->resize(addresses.size());
    if (addresses.empty()) {
        return true;
    }

    bool all_success = true;
    for (size_t start = 0; start < addresses.size(); start += kReadManyBatchSize) {
        const size_t count = std::min(kReadManyBatchSize, addresses.size() - start);
        std::vector<uint8_t> batch_storage(count * size);
        std::vector<iovec> local_iov(count);
        std::vector<iovec> remote_iov(count);
        for (size_t index = 0; index < count; ++index) {
            local_iov[index] = iovec{batch_storage.data() + (index * size), size};
            remote_iov[index] = iovec{reinterpret_cast<void*>(addresses[start + index]), size};
        }

        const size_t expected_size = count * size;
        const ssize_t bytes_read = process_vm_readv(pid_,
                                                    local_iov.data(),
                                                    static_cast<unsigned long>(count),
                                                    remote_iov.data(),
                                                    static_cast<unsigned long>(count),
                                                    0);
        if (bytes_read == static_cast<ssize_t>(expected_size)) {
            for (size_t index = 0; index < count; ++index) {
                (*buffers)[start + index].assign(batch_storage.begin() +
                                                     static_cast<std::ptrdiff_t>(index * size),
                                                 batch_storage.begin() +
                                                     static_cast<std::ptrdiff_t>((index + 1) * size));
            }
            continue;
        }

        all_success = false;
        for (size_t index = 0; index < count; ++index) {
            std::vector<uint8_t> single;
            if (Read(addresses[start + index], size, &single)) {
                (*buffers)[start + index] = std::move(single);
            }
        }
    }

    return all_success;
}

bool ProcessMemoryReader::ReadWithProcessVmReadv(uint64_t address,
                                                 size_t size,
                                                 std::vector<uint8_t>* buffer) const {
    iovec local_iov{buffer->data(), size};
    iovec remote_iov{reinterpret_cast<void*>(address), size};
    const ssize_t bytes_read = process_vm_readv(pid_, &local_iov, 1, &remote_iov, 1, 0);
    return bytes_read == static_cast<ssize_t>(size);
}

bool ProcessMemoryReader::ReadWithPread(uint64_t address,
                                        size_t size,
                                        std::vector<uint8_t>* buffer) const {
    if (mem_fd_ < 0) {
        return false;
    }

    const ssize_t bytes_read = pread64(mem_fd_,
                                       buffer->data(),
                                       size,
                                       static_cast<off64_t>(address));
    return bytes_read == static_cast<ssize_t>(size);
}

bool IsProcessAlive(int pid) {
    if (pid <= 0) {
        return false;
    }

    const int result = kill(pid, 0);
    return result == 0 || errno == EPERM;
}

}  // namespace memory_tool
