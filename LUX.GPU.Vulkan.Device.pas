﻿unit LUX.GPU.Vulkan.Device;

interface //#################################################################### ■

uses System.Generics.Collections,
     vulkan_core, vulkan_win32,
     vulkan.util,
     LUX.GPU.Vulkan.root;

type //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【型】

     TVkDevices<TVulkan_:class> = class;
     TVkDevice<TVulkan_:class>  = class;

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TVkDevices

     TVkDevices<TVulkan_:class> = class( TVkObject<TVulkan_> )
     private
       type TVkDevice_ = TVkDevice<TVulkan_>;
     protected
       _Devices :TObjectList<TVkDevice_>;
       ///// アクセス
       ///// メソッド
       procedure GetDevices;
     public
       constructor Create( const Vulkan_:TVulkan_ );
       procedure AfterConstruction; override;
       destructor Destroy; override;
       ///// プロパティ
       property Devices :TObjectList<TVkDevice_> read _Devices;
       ///// メソッド
     end;

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TVkDevice

     TVkDevice<TVulkan_:class> = class
     private
       type TVkDevices_ = TVkDevices<TVulkan_>;
     protected
       _Devices    :TVkDevices_;
       _PhysHandle :VkPhysicalDevice;
       _Props      :VkPhysicalDeviceProperties;
       _Handle     :VkDevice;
       _Extensions :TArray<PAnsiChar>;
       /////
       ///// メソッド
       function init_device_extension_properties( var layer_props_:T_layer_properties ) :VkResult;
       procedure GetQueueFamilys;
       procedure CreateHandle;
       procedure DestroHandle;
     public
       constructor Create( const Devices_:TVkDevices_; const Handle_:VkPhysicalDevice );
       procedure AfterConstruction; override;
       destructor Destroy; override;
       ///// プロパティ
       property Devices    :TVkDevices_                read _Devices   ;
       property PhysHandle :VkPhysicalDevice           read _PhysHandle;
       property Props      :VkPhysicalDeviceProperties read _Props     ;
       property Handle     :VkDevice                   read _Handle    ;
     end;

//const //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【定数】

//var //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【変数】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

implementation //############################################################### ■

uses System.Classes,
     LUX.GPU.Vulkan;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TVkShader

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

/////////////////////////////////////////////////////////////////////// アクセス

/////////////////////////////////////////////////////////////////////// メソッド

procedure TVkDevices<TVulkan_>.GetDevices;
var
   DsN :UInt32;
   Ds :TArray<VkPhysicalDevice>;
   D :VkPhysicalDevice;
begin
     Assert( ( vkEnumeratePhysicalDevices( TVulkan( Vulkan ).Instance.Handle, @DsN, nil ) = VK_SUCCESS ) and ( DsN > 0 ) );

     SetLength( Ds, DsN );

     Assert( ( vkEnumeratePhysicalDevices( TVulkan( Vulkan ).Instance.Handle, @DsN, @Ds[0] ) = VK_SUCCESS ) and ( DsN > 0 ) );

     for D in Ds do _Devices.Add( TVkDevice_.Create( Self, D ) );
end;

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

constructor TVkDevices<TVulkan_>.Create( const Vulkan_:TVulkan_ );
begin
     inherited;

     _Devices := TObjectList<TVkDevice_>.Create;
end;

procedure TVkDevices<TVulkan_>.AfterConstruction;
begin
     inherited;

     GetDevices;
end;

destructor TVkDevices<TVulkan_>.Destroy;
begin
     _Devices.Free;

     inherited;
end;

/////////////////////////////////////////////////////////////////////// メソッド

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TVkDevice

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

function TVkDevice<TVulkan_>.init_device_extension_properties( var layer_props_:T_layer_properties ) :VkResult;
var
   device_extensions      :P_VkExtensionProperties;
   device_extension_count :UInt32;
   layer_name             :PAnsiChar;
begin
     layer_name := layer_props_.properties.layerName;

     repeat
           Result := vkEnumerateDeviceExtensionProperties( PhysHandle, layer_name, @device_extension_count, nil );
           if Result <> VK_SUCCESS then Exit;

           if device_extension_count = 0 then Exit( VK_SUCCESS );

           SetLength( layer_props_.device_extensions, device_extension_count );
           device_extensions := @layer_props_.device_extensions[0];
           Result := vkEnumerateDeviceExtensionProperties( PhysHandle, layer_name, @device_extension_count, device_extensions );

     until Result <> VK_INCOMPLETE;
end;

procedure TVkDevice<TVulkan_>.GetQueueFamilys;
var
   I :Integer;
begin
     vkGetPhysicalDeviceQueueFamilyProperties( PhysHandle, @TVkDevices( Devices ).Vulkan.Info.queue_family_count, nil );
     Assert( TVkDevices( Devices ).Vulkan.Info.queue_family_count > 1 );

     SetLength( TVkDevices( Devices ).Vulkan.Info.queue_props, TVkDevices( Devices ).Vulkan.Info.queue_family_count );
     vkGetPhysicalDeviceQueueFamilyProperties( PhysHandle, @TVkDevices( Devices ).Vulkan.Info.queue_family_count, @TVkDevices( Devices ).Vulkan.Info.queue_props[0] );
     Assert( TVkDevices( Devices ).Vulkan.Info.queue_family_count > 1 );

     (* This is as good a place as any to do this *)
     vkGetPhysicalDeviceMemoryProperties( PhysHandle, @TVkDevices( Devices ).Vulkan.Info.memory_properties );
     vkGetPhysicalDeviceProperties( PhysHandle, @_Props );
     (* query device extensions for enabled layers *)
     for I := 0 to Length( TVkDevices( Devices ).Vulkan.Layers )-1
     do init_device_extension_properties( TVkDevices( Devices ).Vulkan.Layers[I] );
end;

procedure TVkDevice<TVulkan_>.CreateHandle;
var
   queue_info       :VkDeviceQueueCreateInfo;
   queue_priorities :array [ 0..1-1 ] of Single;
   device_info      :VkDeviceCreateInfo;
begin
     queue_priorities[0]         := 0;
     queue_info                  := Default( VkDeviceQueueCreateInfo );
     queue_info.sType            := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
     queue_info.pNext            := nil;
     queue_info.queueCount       := 1;
     queue_info.pQueuePriorities := @queue_priorities[0];
     queue_info.queueFamilyIndex := TVkDevices( Devices ).Vulkan.Info.graphics_queue_family_index;
     device_info                              := Default( VkDeviceCreateInfo );
     device_info.sType                        := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
     device_info.pNext                        := nil;
     device_info.queueCreateInfoCount         := 1;
     device_info.pQueueCreateInfos            := @queue_info;
     device_info.enabledExtensionCount        := Length( _Extensions );
     if device_info.enabledExtensionCount > 0
     then device_info.ppEnabledExtensionNames := @_Extensions[0]
     else device_info.ppEnabledExtensionNames := nil;
     device_info.pEnabledFeatures             := nil;
     Assert( vkCreateDevice( PhysHandle, @device_info, nil, @_Handle ) = VK_SUCCESS );
end;

procedure TVkDevice<TVulkan_>.DestroHandle;
begin
     vkDeviceWaitIdle( _Handle );
     vkDestroyDevice( _Handle, nil );
end;

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

constructor TVkDevice<TVulkan_>.Create( const Devices_:TVkDevices_; const Handle_:VkPhysicalDevice );
begin
     inherited Create;

     _Devices := Devices_;
     _PhysHandle  := Handle_;
end;

procedure TVkDevice<TVulkan_>.AfterConstruction;
begin
     inherited;

     GetQueueFamilys;

     _Extensions := _Extensions + [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];

     CreateHandle;
end;

destructor TVkDevice<TVulkan_>.Destroy;
begin
     DestroHandle;

     inherited;
end;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

//############################################################################## □

initialization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 初期化

finalization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 最終化

end. //######################################################################### ■