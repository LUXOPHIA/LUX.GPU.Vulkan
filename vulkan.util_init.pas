﻿unit vulkan.util_init;

(*
 * Vulkan Samples
 *
 * Copyright (C) 2015-2020 Valve Corporation
 * Copyright (C) 2015-2020 LunarG, Inc.
 * Copyright (C) 2015-2020 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

interface //#################################################################### ■

uses vulkan_core, vulkan_win32,
     vulkan.util,
     LUX.Code.C;

//type //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【型】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

//const //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【定数】

//var //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【変数】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

//////////////////////////////////////////////////////////////////////////////// 01-init_instance

function init_global_extension_properties( var layer_props_:T_layer_properties ) :VkResult;
function init_global_layer_properties( var info_:T_sample_info ) :VkResult;

//////////////////////////////////////////////////////////////////////////////// 02-enumerate_devices

function init_instance( var info_:T_sample_info; const app_short_name_:P_char ) :VkResult;

//////////////////////////////////////////////////////////////////////////////// 03-init_device

function init_device_extension_properties( var info_:T_sample_info; var layer_props_:T_layer_properties ) :VkResult;
function init_enumerate_device( var info_:T_sample_info; gpu_count_:T_uint32_t = 1 ) :VkResult;
procedure destroy_instance( var info_:T_sample_info );

//////////////////////////////////////////////////////////////////////////////// 04-init_command_buffer

procedure init_queue_family_index( var info_:T_sample_info );
function init_device( var info_:T_sample_info ) :VkResult;
procedure destroy_device( var info_:T_sample_info );

//////////////////////////////////////////////////////////////////////////////// 05-init_swapchain

procedure init_instance_extension_names( var info_:T_sample_info );
procedure init_device_extension_names( var info_:T_sample_info );
procedure init_window_size( var info_:T_sample_info; default_width_,default_height_:UInt32 );
procedure init_connection( var info_:T_sample_info );
procedure init_window( var info_:T_sample_info );
procedure destroy_window( var info_:T_sample_info );

//////////////////////////////////////////////////////////////////////////////// 06-init_depth_buffer

procedure init_swapchain_extension( var info_:T_sample_info );

//////////////////////////////////////////////////////////////////////////////// 07-init_uniform_buffer

//////////////////////////////////////////////////////////////////////////////// 08-init_pipeline_layout

//////////////////////////////////////////////////////////////////////////////// 09-init_descriptor_set

procedure init_uniform_buffer( var info:T_sample_info );
procedure init_descriptor_and_pipeline_layouts( var info:T_sample_info; use_texture:T_bool; descSetLayoutCreateFlags:VkDescriptorSetLayoutCreateFlags = 0 );
procedure destroy_uniform_buffer( var info:T_sample_info );
procedure destroy_descriptor_and_pipeline_layouts( var info:T_sample_info );

implementation //############################################################### ■

uses System.Types, System.Math,
     FMX.Types,
     Winapi.Windows, Winapi.Messages,
     LUX, LUX.D1, LUX.D2, LUX.D3, LUX.D4, LUX.D4x4;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

//////////////////////////////////////////////////////////////////////////////// 01-init_instance

function init_global_extension_properties( var layer_props_:T_layer_properties ) :VkResult;
var
   instance_extensions      :P_VkExtensionProperties;
   instance_extension_count :T_uint32_t;
   layer_name               :P_char;
begin
     layer_name := layer_props_.properties.layerName;

     repeat
           Result := vkEnumerateInstanceExtensionProperties( layer_name, @instance_extension_count, nil );
           if Result <> VK_SUCCESS then Exit;

           if instance_extension_count = 0 then Exit( VK_SUCCESS );

           SetLength( layer_props_.instance_extensions, instance_extension_count );
           instance_extensions := @layer_props_.instance_extensions[0];
           Result := vkEnumerateInstanceExtensionProperties( layer_name, @instance_extension_count, instance_extensions );

     until Result <> VK_INCOMPLETE;
end;

function init_global_layer_properties( var info_:T_sample_info ) :VkResult;
var
   instance_layer_count :T_uint32_t;
   vk_props             :TArray<VkLayerProperties>;
   i                    :T_uint32_t;
   layer_props          :T_layer_properties;
begin
     (*
      * It's possible, though very rare, that the number of
      * instance layers could change. For example, installing something
      * could include new layers that the loader would pick up
      * between the initial query for the count and the
      * request for VkLayerProperties. The loader indicates that
      * by returning a VK_INCOMPLETE status and will update the
      * the count parameter.
      * The count parameter will be updated with the number of
      * entries loaded into the data pointer - in case the number
      * of layers went down or is smaller than the size given.
      *)
     repeat
           Result := vkEnumerateInstanceLayerProperties( @instance_layer_count, nil );
           if Result <> VK_SUCCESS then Exit;

           if instance_layer_count = 0 then Exit( VK_SUCCESS );

           SetLength( vk_props, instance_layer_count );

           Result := vkEnumerateInstanceLayerProperties( @instance_layer_count, @vk_props[0] );

        until Result <> VK_INCOMPLETE;

     (*
      * Now gather the extension list for each instance layer.
      *)
     for i := 0 to instance_layer_count-1 do
     begin
          layer_props.properties := vk_props[i];
          Result := init_global_extension_properties( layer_props );
          if Result <> VK_SUCCESS then Exit;
          info_.instance_layer_properties := info_.instance_layer_properties + [ layer_props ];
     end;
     vk_props := nil;
end;

//////////////////////////////////////////////////////////////////////////////// 02-enumerate_devices

function init_instance( var info_:T_sample_info; const app_short_name_:P_char ) :VkResult;
var
   app_info  :VkApplicationInfo;
   inst_info :VkInstanceCreateInfo;
begin
    app_info.sType              := VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app_info.pNext              := nil;
    app_info.pApplicationName   := app_short_name_;
    app_info.applicationVersion := 1;
    app_info.pEngineName        := app_short_name_;
    app_info.engineVersion      := 1;
    app_info.apiVersion         := VK_API_VERSION_1_0;

    inst_info.sType                    := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    inst_info.pNext                    := nil;
    inst_info.flags                    := 0;
    inst_info.pApplicationInfo         := @app_info;
    inst_info.enabledLayerCount        := Length( info_.instance_layer_names );
    if Length( info_.instance_layer_names ) > 0
    then inst_info.ppEnabledLayerNames := @info_.instance_layer_names[0]
    else inst_info.ppEnabledLayerNames := nil;
    inst_info.enabledExtensionCount    := Length( info_.instance_extension_names );
    inst_info.ppEnabledExtensionNames  := @info_.instance_extension_names[0];

    Result := vkCreateInstance( @inst_info, nil, @info_.inst );
    Assert( Result = VK_SUCCESS );
end;

//////////////////////////////////////////////////////////////////////////////// 03-init_device

function init_device_extension_properties( var info_:T_sample_info; var layer_props_:T_layer_properties ) :VkResult;
var
   device_extensions      :P_VkExtensionProperties;
   device_extension_count :T_uint32_t;
   layer_name             :P_char;
begin
     layer_name := layer_props_.properties.layerName;

     repeat
           Result := vkEnumerateDeviceExtensionProperties( info_.gpus[0], layer_name, @device_extension_count, nil );
           if Result <> VK_SUCCESS then Exit;

           if device_extension_count = 0 then Exit( VK_SUCCESS );

           SetLength( layer_props_.device_extensions, device_extension_count );
           device_extensions := @layer_props_.device_extensions[0];
           Result := vkEnumerateDeviceExtensionProperties( info_.gpus[0], layer_name, @device_extension_count, device_extensions );

     until Result <> VK_INCOMPLETE;
end;

function init_enumerate_device( var info_:T_sample_info; gpu_count_:T_uint32_t = 1 ) :VkResult;
var
   req_count :T_uint32_t;
   I         :Integer;
begin
     req_count := gpu_count_;
     {Result := }vkEnumeratePhysicalDevices( info_.inst, @gpu_count_, nil );
     Assert( gpu_count_ > 0 );
     SetLength( info_.gpus, gpu_count_ );

     Result := vkEnumeratePhysicalDevices( info_.inst, @gpu_count_, @info_.gpus[0] );
     Assert( ( Result = VK_SUCCESS ) and ( gpu_count_ >= req_count ) );

     vkGetPhysicalDeviceQueueFamilyProperties( info_.gpus[0], @info_.queue_family_count, nil );
     Assert( info_.queue_family_count >= 1 );

     SetLength( info_.queue_props, info_.queue_family_count );
     vkGetPhysicalDeviceQueueFamilyProperties( info_.gpus[0], @info_.queue_family_count, @info_.queue_props[0] );
     Assert( info_.queue_family_count >= 1 );

     (* This is as good a place as any to do this *)
     vkGetPhysicalDeviceMemoryProperties( info_.gpus[0], @info_.memory_properties );
     vkGetPhysicalDeviceProperties( info_.gpus[0], @info_.gpu_props );
     (* query device extensions for enabled layers *)
     for I := 0 to Length( info_.instance_layer_properties )-1
     do init_device_extension_properties( info_, info_.instance_layer_properties[I] );
end;

procedure destroy_instance( var info_:T_sample_info );
begin
     vkDestroyInstance( info_.inst, nil );
end;

//////////////////////////////////////////////////////////////////////////////// 04-init_command_buffer

procedure init_queue_family_index( var info_:T_sample_info );
var
   found :T_bool;
   i     :T_unsigned_int;
begin
     (* This routine simply finds a graphics queue for a later vkCreateDevice,
      * without consideration for which queue family can present an image.
      * Do not use this if your intent is to present later in your sample,
      * instead use the init_connection, init_window, init_swapchain_extension,
      * init_device call sequence to get a graphics and present compatible queue
      * family
      *)

     vkGetPhysicalDeviceQueueFamilyProperties( info_.gpus[0], @info_.queue_family_count, nil );
     Assert( info_.queue_family_count >= 1 );

     SetLength( info_.queue_props, info_.queue_family_count );
     vkGetPhysicalDeviceQueueFamilyProperties( info_.gpus[0], @info_.queue_family_count, @info_.queue_props[0] );
     Assert( info_.queue_family_count >= 1 );

     found := False;
     for i := 0 to info_.queue_family_count-1 do
     begin
          if ( info_.queue_props[i].queueFlags and VkQueueFlags( VK_QUEUE_GRAPHICS_BIT ) ) > 0 then
          begin
               info_.graphics_queue_family_index := i;
               found := True;
               Break;
          end;
     end;
     Assert( found );
end;

function init_device( var info_:T_sample_info ) :VkResult;
var
   queue_info       :VkDeviceQueueCreateInfo;
   queue_priorities :array [ 0..0 ] of T_float;
   device_info      :VkDeviceCreateInfo;
begin
     queue_priorities[0]         := 0;
     queue_info.sType            := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
     queue_info.pNext            := nil;
     queue_info.queueCount       := 1;
     queue_info.pQueuePriorities := @queue_priorities[0];
     queue_info.queueFamilyIndex := info_.graphics_queue_family_index;

     device_info.sType                        := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
     device_info.pNext                        := nil;
     device_info.queueCreateInfoCount         := 1;
     device_info.pQueueCreateInfos            := @queue_info;
     device_info.enabledExtensionCount        := Length( info_.device_extension_names );
     if device_info.enabledExtensionCount > 0
     then device_info.ppEnabledExtensionNames := @info_.device_extension_names[0]
     else device_info.ppEnabledExtensionNames := nil;
     device_info.pEnabledFeatures             := nil;

     Result := vkCreateDevice( info_.gpus[0], @device_info, nil, @info_.device );
     Assert( Result = VK_SUCCESS );
end;

procedure destroy_device( var info_:T_sample_info );
begin
     vkDeviceWaitIdle( info_.device );
     vkDestroyDevice( info_.device, nil );
end;

//////////////////////////////////////////////////////////////////////////////// 05-init_swapchain

procedure init_instance_extension_names( var info_:T_sample_info );
begin
     info_.instance_extension_names := info_.instance_extension_names + [ VK_KHR_SURFACE_EXTENSION_NAME         ];
     info_.instance_extension_names := info_.instance_extension_names + [ VK_KHR_WIN32_SURFACE_EXTENSION_NAME   ];
end;

procedure init_device_extension_names( var info_:T_sample_info );
begin
     info_.device_extension_names := info_.device_extension_names + [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];
end;

procedure init_window_size( var info_:T_sample_info; default_width_,default_height_:UInt32 );
begin
     info_.width  := default_width_;
     info_.height := default_height_;
end;

procedure init_connection( var info_:T_sample_info );
begin

end;

procedure run( var info:T_sample_info );
begin
     (* Placeholder for samples that want to show dynamic content *)
end;

function WndProc( hwnd:HWND; uMsg:UINT; wParam:WPARAM; lParam:LPARAM ) :LRESULT; stdcall;
var
   info :P_sample_info;
begin
     info := P_sample_info( GetWindowLongPtr( hWnd, GWLP_USERDATA ) );

     case uMsg of
     WM_CLOSE: PostQuitMessage( 0 );
     WM_PAINT: begin
                    run( info^ );
                    Exit( 0 );
               end;
     else
     end;
     Result := DefWindowProc( hWnd, uMsg, wParam, lParam );
end;

procedure init_window( var info_:T_sample_info );
var
   win_class :WNDCLASSEX;
   wr        :TRect;
begin
     Assert( info_.width  > 0 );
     Assert( info_.height > 0 );

     info_.connection := GetModuleHandle( nil );
     info_.name       := 'Sample';

     // Initialize the window class structure:
     win_class.cbSize        := SizeOf( WNDCLASSEX );
     win_class.style         := CS_HREDRAW or CS_VREDRAW;
     win_class.lpfnWndProc   := @WndProc;
     win_class.cbClsExtra    := 0;
     win_class.cbWndExtra    := 0;
     win_class.hInstance     := info_.connection;  // hInstance
     win_class.hIcon         := LoadIcon( 0, IDI_APPLICATION );
     win_class.hCursor       := LoadCursor( 0, IDC_ARROW );
     win_class.hbrBackground := HBRUSH( GetStockObject( WHITE_BRUSH ) );
     win_class.lpszMenuName  := nil;
     win_class.lpszClassName := LPCWSTR( WideString( info_.name ) );
     win_class.hIconSm       := LoadIcon( 0, IDI_WINLOGO );
     // Register window class:
     if RegisterClassEx( win_class ) = 0 then
     begin
          // It didn't work, so try to give a useful error:
          Log.d( 'Unexpected error trying to start the application!' );
          RunError( 1 );
     end;
     // Create window with the registered class:
     wr := TRect.Create( 0, 0, info_.width, info_.height );
     AdjustWindowRect( wr, WS_OVERLAPPEDWINDOW, False );
     info_.window := CreateWindowEx( 0,
                                    LPCWSTR( WideString( info_.name ) ),              // class name
                                    LPCWSTR( WideString( info_.name ) ),              // app name
                                    WS_OVERLAPPEDWINDOW or WS_VISIBLE or WS_SYSMENU,  // window style
                                    100, 100,                                         // x/y coords
                                    wr.right - wr.left,                               // width
                                    wr.bottom - wr.top,                               // height
                                    0,                                                // handle to parent
                                    0,                                                // handle to menu
                                    info_.connection,                                 // hInstance
                                    nil );                                            // no extra parameters
     if info_.window = 0 then
     begin
          // It didn't work, so try to give a useful error:
          Log.d( 'Cannot create a window in which to draw!' );
          RunError( 1 );
     end;
     SetWindowLongPtr( info_.window, GWLP_USERDATA, LONG_PTR( @info_ ) );
end;

procedure destroy_window( var info_:T_sample_info );
begin
     vkDestroySurfaceKHR( info_.inst, info_.surface, nil );
     DestroyWindow( info_.window );
end;

//////////////////////////////////////////////////////////////////////////////// 06-init_depth_buffer

(* Use this surface format if it's available.  This ensures that generated
* images are similar on different devices and with different drivers.
*)
const PREFERRED_SURFACE_FORMAT = VK_FORMAT_B8G8R8A8_UNORM;

procedure init_swapchain_extension( var info_:T_sample_info );
var
   res              :VkResult;
   createInfo       :VkWin32SurfaceCreateInfoKHR;
   pSupportsPresent :TArray<VkBool32>;
   i                :T_uint32_t;
   formatCount      :T_uint32_t;
   surfFormats      :TArray<VkSurfaceFormatKHR>;
begin
     (* DEPENDS on init_connection() and init_window() *)

     // Construct the surface description:
     createInfo.sType     := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
     createInfo.pNext     := nil;
     createInfo.hinstance := info_.connection;
     createInfo.hwnd      := info_.window;
     res := vkCreateWin32SurfaceKHR( info_.inst, @createInfo, nil, @info_.surface );
     Assert( res = VK_SUCCESS );

     // Iterate over each queue to learn whether it supports presenting:
     SetLength( pSupportsPresent, info_.queue_family_count );
     for i := 0 to info_.queue_family_count-1
     do vkGetPhysicalDeviceSurfaceSupportKHR( info_.gpus[0], i, info_.surface, @pSupportsPresent[i] );

     // Search for a graphics and a present queue in the array of queue
     // families, try to find one that supports both
     info_.graphics_queue_family_index := UINT32_MAX;
     info_.present_queue_family_index  := UINT32_MAX;
     for i := 0 to info_.queue_family_count-1 do
     begin
          if ( info_.queue_props[i].queueFlags and VkQueueFlags( VK_QUEUE_GRAPHICS_BIT ) ) <> 0 then
          begin
               if info_.graphics_queue_family_index = UINT32_MAX then info_.graphics_queue_family_index := i;

               if pSupportsPresent[i] = VK_TRUE then
               begin
                    info_.graphics_queue_family_index := i;
                    info_.present_queue_family_index  := i;
                    Break;
               end;
          end;
     end;

     if info_.present_queue_family_index = UINT32_MAX then
     begin
          // If didn't find a queue that supports both graphics and present, then
          // find a separate present queue.
          for i := 0 to info_.queue_family_count-1 do
          begin
               if pSupportsPresent[i] = VK_TRUE then
               begin
                    info_.present_queue_family_index := i;
                    Break;
               end;
          end;
     end;
     pSupportsPresent := nil;

     // Generate error if could not find queues that support graphics
     // and present
     if ( info_.graphics_queue_family_index = UINT32_MAX ) or ( info_.present_queue_family_index = UINT32_MAX ) then
     begin
          Log.d( 'Could not find a queues for both graphics and present' );
          RunError( 256-1 );
     end;

     // Get the list of VkFormats that are supported:
     res := vkGetPhysicalDeviceSurfaceFormatsKHR( info_.gpus[0], info_.surface, @formatCount, nil );
     Assert( res = VK_SUCCESS );
     SetLength( surfFormats, formatCount );
     res := vkGetPhysicalDeviceSurfaceFormatsKHR( info_.gpus[0], info_.surface, @formatCount, @surfFormats[0] );
     Assert( res = VK_SUCCESS );

     // If the device supports our preferred surface format, use it.
     // Otherwise, use whatever the device's first reported surface
     // format is.
     Assert( formatCount >= 1 );
     info_.format := surfFormats[0].format;
     for i := 0 to formatCount-1 do
     begin
          if surfFormats[i].format = PREFERRED_SURFACE_FORMAT then
          begin
               info_.format := PREFERRED_SURFACE_FORMAT;
               break;
          end;
     end;

     surfFormats := nil;
end;

//////////////////////////////////////////////////////////////////////////////// 07-init_uniform_buffer

//////////////////////////////////////////////////////////////////////////////// 08-init_pipeline_layout

//////////////////////////////////////////////////////////////////////////////// 09-init_descriptor_set

procedure init_uniform_buffer( var info:T_sample_info );
var
   res        :VkResult;
   pass       :T_bool;
   fov        :T_float;
   buf_info   :VkBufferCreateInfo;
   mem_reqs   :VkMemoryRequirements;
   alloc_info :VkMemoryAllocateInfo;
   pData      :P_uint8_t;
begin
     fov := DegToRad( 45 );
     if info.width > info.height then
     begin
          fov := fov * info.height / info.width;
     end;
     info.Projection := TSingleM4.ProjPersH( fov, info.width / info.height, 0.1, 100 );
     info.View := TSingleM4.LookAt( TSingle3D.Create( -5, -3, -10 ),    // Camera is at (-5,3,-10), in World Space
                                    TSingle3D.Create(  0,  0,   0 ),    // and looks at the origin
                                    TSingle3D.Create(  0, -1,   0 ) );  // Head is up (set to 0,-1,0 to look upside-down)

     info.Model := TSingleM4.Identity;
     // Vulkan clip space has inverted Y and half Z.
     info.Clip := TSingleM4.Create( +1.0,  0.0,  0.0,  0.0,
                                     0.0, -1.0,  0.0,  0.0,
                                     0.0,  0.0, +0.5,  0.0,
                                     0.0,  0.0, +0.5, +1.0 );

     info.MVP := info.Clip * info.Projection * info.View * info.Model;

     (* VULKAN_KEY_START *)
     buf_info.sType                 := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
     buf_info.pNext                 := nil;
     buf_info.usage                 := VkBufferUsageFlags( VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT );
     buf_info.size                  := sizeof(info.MVP);
     buf_info.queueFamilyIndexCount := 0;
     buf_info.pQueueFamilyIndices   := nil;
     buf_info.sharingMode           := VK_SHARING_MODE_EXCLUSIVE;
     buf_info.flags                 := 0;
     res := vkCreateBuffer( info.device, @buf_info, nil, @info.uniform_data.buf );
     Assert( res = VK_SUCCESS );

     vkGetBufferMemoryRequirements( info.device, info.uniform_data.buf, @mem_reqs );

     alloc_info.sType           := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
     alloc_info.pNext           := nil;
     alloc_info.memoryTypeIndex := 0;

     alloc_info.allocationSize := mem_reqs.size;
     pass := memory_type_from_properties( info, mem_reqs.memoryTypeBits,
                                          VkFlags( VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT ) or VkFlags( VK_MEMORY_PROPERTY_HOST_COHERENT_BIT ),
                                          alloc_info.memoryTypeIndex );
     Assert( pass, 'No mappable, coherent memory' );

     res := vkAllocateMemory( info.device, @alloc_info, nil, @info.uniform_data.mem );
     Assert( res = VK_SUCCESS );

     res := vkMapMemory( info.device, info.uniform_data.mem, 0, mem_reqs.size, 0, @pData );
     Assert( res = VK_SUCCESS );

     Move( pData^, info.MVP, SizeOf( info.MVP ) );

     vkUnmapMemory( info.device, info.uniform_data.mem );

     res := vkBindBufferMemory( info.device, info.uniform_data.buf, info.uniform_data.mem, 0 );
     Assert( res = VK_SUCCESS );

     info.uniform_data.buffer_info.buffer := info.uniform_data.buf;
     info.uniform_data.buffer_info.offset := 0;
     info.uniform_data.buffer_info.range  := SizeOf( info.MVP );
end;

procedure init_descriptor_and_pipeline_layouts( var info:T_sample_info; use_texture:T_bool; descSetLayoutCreateFlags:VkDescriptorSetLayoutCreateFlags = 0 );
var
   layout_bindings           :array [ 0..2-1 ] of VkDescriptorSetLayoutBinding;
   descriptor_layout         :VkDescriptorSetLayoutCreateInfo;
   res                       :VkResult;
   pPipelineLayoutCreateInfo :VkPipelineLayoutCreateInfo;
begin
     layout_bindings[0].binding            := 0;
     layout_bindings[0].descriptorType     := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
     layout_bindings[0].descriptorCount    := 1;
     layout_bindings[0].stageFlags         := VkShaderStageFlags( VK_SHADER_STAGE_VERTEX_BIT );
     layout_bindings[0].pImmutableSamplers := nil;

     if use_texture then
     begin
          layout_bindings[1].binding            := 1;
          layout_bindings[1].descriptorType     := VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
          layout_bindings[1].descriptorCount    := 1;
          layout_bindings[1].stageFlags         := VkShaderStageFlags( VK_SHADER_STAGE_FRAGMENT_BIT );
          layout_bindings[1].pImmutableSamplers := nil;
     end;

     (* Next take layout bindings and use them to create a descriptor set layout
     *)
     descriptor_layout.sType             := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
     descriptor_layout.pNext             := nil;
     descriptor_layout.flags             := descSetLayoutCreateFlags;
     if use_texture
     then descriptor_layout.bindingCount := 2
     else descriptor_layout.bindingCount := 1;
     descriptor_layout.pBindings         := @layout_bindings[0];

     SetLength( info.desc_layout, NUM_DESCRIPTOR_SETS );
     res := vkCreateDescriptorSetLayout( info.device, @descriptor_layout, nil, @info.desc_layout[0] );
     Assert( res = VK_SUCCESS );

     (* Now use the descriptor layout to create a pipeline layout *)
     pPipelineLayoutCreateInfo.sType                  := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
     pPipelineLayoutCreateInfo.pNext                  := nil;
     pPipelineLayoutCreateInfo.pushConstantRangeCount := 0;
     pPipelineLayoutCreateInfo.pPushConstantRanges    := nil;
     pPipelineLayoutCreateInfo.setLayoutCount         := NUM_DESCRIPTOR_SETS;
     pPipelineLayoutCreateInfo.pSetLayouts            := @info.desc_layout[0];

     res := vkCreatePipelineLayout( info.device, @pPipelineLayoutCreateInfo, nil, @info.pipeline_layout );
     Assert( res = VK_SUCCESS );
end;

procedure destroy_uniform_buffer( var info:T_sample_info );
begin
     vkDestroyBuffer( info.device, info.uniform_data.buf, nil );
     vkFreeMemory( info.device, info.uniform_data.mem, nil );
end;

procedure destroy_descriptor_and_pipeline_layouts( var info:T_sample_info );
var
   i :T_int;
begin
     for i := 0 to NUM_DESCRIPTOR_SETS-1 do vkDestroyDescriptorSetLayout( info.device, info.desc_layout[i], nil );
     vkDestroyPipelineLayout( info.device, info.pipeline_layout, nil );
end;

end. //######################################################################### ■