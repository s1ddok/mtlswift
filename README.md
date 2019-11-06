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

**Example**:
```C++
#include <metal_stdlib>

using namespace metal;

namespace mtlswift {}
```

#### Arguments 

* `mtlswift:`
  **Description**: declaration prefix.
  **Example**:
  ```C++
  /// mtlswift: ...
  kernel void dummyKernel(...
  ```

* `swiftName:`
  **Description**: ...
  **Example**:
  ```C++
  ...
  ```

* `accessLevel:`
  **Description**: ...
  **Example**:
  ```C++
  ...
  ```


* `swiftParameterName:`
  **Description**: ...
  **Example**:
  ```C++
  ...
  ```

* `swiftParameteterType:`
  **Description**: the name and the type of the buffers passed to the kernel.
  **Example**:
  ```C++
  /// mtlswift:swiftParameteterType:offset:vector_ushort2
  /// mtlswift:swiftParameteterType:intensities:vector_float3
  kernel void dummyKernel(texture2d<half, access::read_write> inPlaceTexture [[ texture(0) ]],
                          constant ushort2& offset [[ buffer(0) ]],
                          constant float3& intensities [[buffer(1)]],
                          ...
  ```

* `dispatch:`
  **Description**: dispatch type.
  * `none`
    **Description**: ...
  * `even:`
    **Description**: ...
  * `exact:`
    **Description**: ...
  * `optimal`
    **Description**: ...
  * `over:`
    **Description**: ...

  **Example**:
  ```C++
  /// mtlswift:dispatch:optimal(4):over:sourceTexture
  kernel void dummyKernel(texture2d<half, access::read> sourceTexture [[ texture(0) ]],
                          ...
  ```

* `threadgroupSize:`
  **Description**: threadgroup size.
  * `max`
    **Description**: ...
  * `provided`
    **Description**: ...
  * `executionWidth`
    **Description**: ...

  **Example**:
  ```C++
  ...
  ```

* `threadgroupMemory`
  **Description**: threadgroupMemory.
  * `total:`
    **Description**: ...
  * `thread:`
    **Description**: ...
  * `provided:`
    **Description**: ...
  * `total`
    **Description**: ...

  **Example**:
  ```C++
  ...
  ```
