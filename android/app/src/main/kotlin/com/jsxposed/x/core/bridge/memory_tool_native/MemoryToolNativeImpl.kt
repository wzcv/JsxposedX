package com.jsxposed.x.core.bridge.memory_tool_native

import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.lang.reflect.Method

class MemoryToolNativeImpl(val context: Context) : MemoryToolNative {
    private val memoryTool = MemoryTool(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun getPid(packageName: String, callback: (Result<Long>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getPid(packageName)
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    override fun getProcessInfo(offset: Long, limit: Long, callback: (Result<List<ProcessInfo>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getProcessInfo(offset.toInt(), limit.toInt())
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getMemoryRegions(query: MemoryRegionQuery, callback: (Result<List<MemoryRegion>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getMemoryRegions(query)
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getSearchSessionState(callback: (Result<SearchSessionState>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getSearchSessionState()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getSearchTaskState(callback: (Result<SearchTaskState>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getSearchTaskState()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getSearchResults(offset: Long, limit: Long, callback: (Result<List<SearchResult>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getSearchResults(offset.toInt(), limit.toInt())
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerScanSessionState(callback: (Result<PointerScanSessionState>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getPointerScanSessionState()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerScanTaskState(callback: (Result<PointerScanTaskState>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getPointerScanTaskState()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerScanResults(offset: Long, limit: Long, callback: (Result<List<PointerScanResult>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getPointerScanResults(offset.toInt(), limit.toInt())
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerScanChaseHint(callback: (Result<PointerScanChaseHint>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getPointerScanChaseHint()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerAutoChaseState(callback: (Result<PointerAutoChaseState>) -> Unit) {
        scope.launch {
            try {
                val result = invokeOptionalMemoryToolMethod<PointerAutoChaseState>(
                    methodName = "getPointerAutoChaseState"
                )
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getPointerAutoChaseLayerResults(
        layerIndex: Long,
        offset: Long,
        limit: Long,
        callback: (Result<List<PointerScanResult>>) -> Unit
    ) {
        scope.launch {
            try {
                val result = invokeOptionalMemoryToolMethod<List<PointerScanResult>>(
                    methodName = "getPointerAutoChaseLayerResults",
                    layerIndex.toInt(),
                    offset.toInt(),
                    limit.toInt()
                )
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun readMemoryValues(requests: List<MemoryReadRequest>, callback: (Result<List<MemoryValuePreview>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.readMemoryValues(requests)
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun writeMemoryValue(request: MemoryWriteRequest, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.writeMemoryValue(request)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun setMemoryFreeze(request: MemoryFreezeRequest, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.setMemoryFreeze(request)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun getFrozenMemoryValues(callback: (Result<List<FrozenMemoryValue>>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.getFrozenMemoryValues()
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun isProcessPaused(pid: Long, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            try {
                val result = memoryTool.isProcessPaused(pid)
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun setProcessPaused(pid: Long, paused: Boolean, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.setProcessPaused(pid, paused)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun firstScan(request: FirstScanRequest, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.firstScan(request)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun nextScan(request: NextScanRequest, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.nextScan(request)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun cancelSearch(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.cancelSearch()
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun resetSearchSession(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.resetSearchSession()
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun startPointerScan(request: PointerScanRequest, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.startPointerScan(request)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun startPointerAutoChase(
        request: PointerAutoChaseRequest,
        callback: (Result<Unit>) -> Unit
    ) {
        scope.launch {
            try {
                invokeOptionalMemoryToolMethod<Unit>(
                    methodName = "startPointerAutoChase",
                    request
                )
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun cancelPointerScan(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.cancelPointerScan()
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun cancelPointerAutoChase(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                invokeOptionalMemoryToolMethod<Unit>(
                    methodName = "cancelPointerAutoChase"
                )
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun resetPointerScanSession(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                memoryTool.resetPointerScanSession()
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun resetPointerAutoChase(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                invokeOptionalMemoryToolMethod<Unit>(
                    methodName = "resetPointerAutoChase"
                )
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    private fun <T> invokeOptionalMemoryToolMethod(
        methodName: String,
        vararg args: Any?
    ): T {
        val method = findCompatibleMethod(methodName, args.toList())
            ?: throw UnsupportedOperationException(
                "Pointer auto chase is unavailable in this build."
            )
        @Suppress("UNCHECKED_CAST")
        return method.invoke(memoryTool, *args) as T
    }

    private fun findCompatibleMethod(
        methodName: String,
        args: List<Any?>
    ): Method? {
        return memoryTool.javaClass.methods.firstOrNull { method ->
            method.name == methodName &&
                method.parameterTypes.size == args.size &&
                method.parameterTypes.withIndex().all { (index, parameterType) ->
                    isCompatibleParameterType(parameterType, args[index])
                }
        }
    }

    private fun isCompatibleParameterType(
        parameterType: Class<*>,
        argument: Any?
    ): Boolean {
        if (argument == null) {
            return !parameterType.isPrimitive
        }
        val argumentClass = argument.javaClass
        return if (parameterType.isPrimitive) {
            primitiveWrapperType(parameterType).isAssignableFrom(argumentClass)
        } else {
            parameterType.isAssignableFrom(argumentClass)
        }
    }

    private fun primitiveWrapperType(type: Class<*>): Class<*> {
        return when (type) {
            java.lang.Boolean.TYPE -> java.lang.Boolean::class.java
            java.lang.Byte.TYPE -> java.lang.Byte::class.java
            java.lang.Character.TYPE -> java.lang.Character::class.java
            java.lang.Double.TYPE -> java.lang.Double::class.java
            java.lang.Float.TYPE -> java.lang.Float::class.java
            java.lang.Integer.TYPE -> java.lang.Integer::class.java
            java.lang.Long.TYPE -> java.lang.Long::class.java
            java.lang.Short.TYPE -> java.lang.Short::class.java
            java.lang.Void.TYPE -> java.lang.Void::class.java
            else -> type
        }
    }
}
