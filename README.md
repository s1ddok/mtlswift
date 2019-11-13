# mtlswift

Experimental code-generator of Swift Metal encoding code

## Usage

Currently, `mtlswift` supports two execution commands:
* `mtlswift generate ...`
  This command generates encoders from provided shaders and stops execution.
* `mtlswift watch ...`
  This command makes mtlswift subscribe to the files changes of provided shaders and continuously update the result.

The user is able to provide multiple paths to the shaders files or folders containing them, for example:
```Shell
mtlswift watch ../shaders_folder/ ../../another_shaders_folder/Shaders.metal
```

> WARNING: This tool currently generates encoders for [`Alloy`](https://github.com/s1ddok/Alloy) syntax. We will probably support vanilla Metal code in the future.

#### CLI Options

List of currently supported arguments:
* `--output ...`, `-o`
  This argument specifies the output file path. If multiple inputs are provided, the encoders file will contain concatenated result.

* `--ignore ...`, `-i`
  The user is able to specify folder or a file to be ignored. This argument might be passed multiple times, for example:
  ```Shell
  mtlswift watch . -i shaders_to_ignore.metal -i folder_to_ignore/
  ```
* `--recursive`, `-r`
  This flag enables recursive search for `.metal` files in provided folders.

## Syntax

To support encoders generation first of all you need to add `namespace mtlswift {}` at the beginning of the file.

```C++
#include <metal_stdlib>

using namespace metal;

namespace mtlswift {}
```

### Customizing generation

Every custom annotation starts with `mtlswift:`. The program uses this declaration prefix to identify the start of a declaration. It must be written in a doc string way right before the kernel.
  
  ```C++
  /// mtlswift: ...
  kernel void exampleKernel(...
  ```

* `dispatch:`

  A dispatch type to use. All of dispatch types has to be followed by either constant amount of threads via literals (like `X, Y, Z`), specifying a target texture to cover via `over:` argument or stating that amount of threads will be provided by user by using `provided`. You can see all of the examples into each section, but you can choose the combination yourself.

  * `even`

    Dispatch threadgroups of a uniform threadgroup size. `Width`, `height` and `depth` describe the grid size.
    
    ```C++
    /// mtlswift:dispatch:even:1024, 768, 1
    kernel void exampleKernel(texture2d<half, access::read_write> inPlaceTexture [[ texture(0) ]],
                              ...
    ```

  * `exact`

    Dispatch threads with threadgroups of non-uniform size. Again, `width`, `height` and `depth` describe the grid size.
    
    ```C++
    /// mtlswift:dispatch:exact:over:inPlaceTexture
    kernel void exampleKernel(texture2d<half, access::read_write> inPlaceTexture [[ texture(0) ]],
                              ...
    ```

  * `optimal(function_constant_index)`
    
    Uses `exact` type if GPU supports non uniform threadgroup size and `over` if it doesn't. This declaration requires a boolean function constant index to be passed to make the decision what dispatch type to use.
    
    ```C++
    constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];

    /// mtlswift:dispatch:optimal(0):provided
    kernel void exampleKernel(texture2d<half, access::read> sourceTexture [[ texture(0) ]],
                              ...
    ```
    
  * `none`
  
    The dispatch type set by default. In this case user has to dispatch kernel manually, after calling `encode` method

* `threadgroupSize:`

  Specify the threadgroup size.
  
  * `X, Y, Z`
  
    Allows to specify constant X, Y and Z dimensions for threadgroup size.
    
  * `max`
  
    This parameter sets the pipeline state's [`max2dThreadgroupSize`](https://github.com/s1ddok/Alloy/blob/b82aa3fde347a81eef9551be7ffc28eec2b93bca/Alloy/MTLComputePipelineState%2BThreads.swift#L24).
    
  * `executionWidth`
  
    This parameter sets the pipeline state's [`executionWidthThreadgroupSize`](https://github.com/s1ddok/Alloy/blob/b82aa3fde347a81eef9551be7ffc28eec2b93bca/Alloy/MTLComputePipelineState%2BThreads.swift#L12).
    
  * `provided`
  
    In this case user has to pass the threadgroup size and an argument to `encode(...` function.

  ```C++
  /// mtlswift:threadgroupSize:provided
  kernel void exampleKernel(texture2d<half, access::read> sourceTexture [[ texture(0) ]],
                            ...
  ```

* `swiftParameteterType:`

  The name and the type of the buffers passed to the kernel.

  ```C++
  /// mtlswift:swiftParameteterType:offset:vector_ushort2
  /// mtlswift:swiftParameteterType:intensities:vector_float3
  kernel void exampleKernel(constant ushort2& offset [[ buffer(0) ]],
                            constant float3& intensities [[buffer(1)]],
                            ...
  ```
* `swiftName:`

   Encoder's name in generated Swift code. Must be followed by a valid Swift identifier.
   
* `accessLevel:`

   Specifies the access visibility of the encoder. Must be followed by either `public`, `open`, `internal`, `private` or `fileprivate`. `internal` is the default.

# Contributors 

* [@eugenebokhan](https://github.com/eugenebokhan) is responsible for nice CLI that this tool has and also for docs that can guide you around

## License

 MIT
