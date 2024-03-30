# --== SAKKI ==--

$code = @'
#define CL_TARGET_OPENCL_VERSION 120
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string.h>
#include <CL/cl.h>

static cl_int (*real_clEnqueueNDRangeKernel)(cl_command_queue, cl_kernel, cl_uint,
                                             const size_t *, const size_t *,
                                             const size_t *, cl_uint,
                                             const cl_event *, cl_event *) = NULL;

int debug_enabled = 0;
useconds_t custom_sleep_delay = 0;

__attribute__((constructor))
void init() {
    char *debug_env = getenv("DEBUG");
    if (debug_env && (strcmp(debug_env, "True") == 0 || strcmp(debug_env, "true") == 0)) {
        debug_enabled = 1;
    }

    char *sleep_env = getenv("SLEEP_DELAY");
    if (sleep_env) {
        custom_sleep_delay = (useconds_t)atoi(sleep_env) * 1000;
    }

    void *handle = dlopen("libOpenCL.so", RTLD_LAZY);
    if (!handle) {
        if (debug_enabled) {
            fprintf(stderr, "Error loading OpenCL library: %s\n", dlerror());
        }
        exit(1);
    }

    *(void**)(&real_clEnqueueNDRangeKernel) = dlsym(handle, "clEnqueueNDRangeKernel");
    if (!real_clEnqueueNDRangeKernel) {
        if (debug_enabled) {
            fprintf(stderr, "Error finding clEnqueueNDRangeKernel: %s\n", dlerror());
        }
        exit(1);
    }

    if (debug_enabled) {
        printf("Intercepted clEnqueueNDRangeKernel.\n");
    }
}

__attribute__((destructor))
void cleanup() {
    if (debug_enabled) {
        printf("Cleanup complete.\n");
    }
}

cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue,
                              cl_kernel kernel,
                              cl_uint work_dim,
                              const size_t *global_work_offset,
                              const size_t *global_work_size,
                              const size_t *local_work_size,
                              cl_uint num_events_in_wait_list,
                              const cl_event *event_wait_list,
                              cl_event *event) {
    cl_int result = real_clEnqueueNDRangeKernel(command_queue, kernel, work_dim,
                                                global_work_offset, global_work_size,
                                                local_work_size, num_events_in_wait_list,
                                                event_wait_list, event);

    if (debug_enabled) {
        printf("Kernel enqueued. Introducing delay of %u microseconds.\n", custom_sleep_delay);
    }

    usleep(custom_sleep_delay);

    return result;
}
'@

$code | Out-File -FilePath "./oclwrapper.c"

& gcc -fPIC -shared -o liboclwrapper.so oclwrapper.c -ldl -lOpenCL

Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Compilation complete. To use the library, preload it before running your application like this:" -ForegroundColor Yellow
Write-Host "LD_PRELOAD=./liboclwrapper.so SLEEP_DELAY=35 ./postcli [parameters]" -ForegroundColor Cyan
Write-Host "LD_PRELOAD=./liboclwrapper.so SLEEP_DELAY=35 ./h9-miner-spacemesh-linux-amd64 -gpuServer" -ForegroundColor Cyan
