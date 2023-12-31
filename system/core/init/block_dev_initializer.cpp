// Copyright (C) 2020 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <chrono>
#include <string_view>
#include <vector>

#include <android-base/chrono_utils.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include <fs_mgr.h>
#include "virtual_dev_initializer.h"
#include "block_dev_initializer.h"

namespace android {
namespace init {

using android::base::Timer;
using namespace std::chrono_literals;

BlockDevInitializer::BlockDevInitializer() : uevent_listener_(16 * 1024 * 1024) {
    auto boot_devices = android::fs_mgr::GetBootDevices();
    device_handler_ = std::make_unique<DeviceHandler>(
            std::vector<Permissions>{}, std::vector<SysfsPermissions>{}, std::vector<Subsystem>{},
            std::move(boot_devices), false);
}

bool BlockDevInitializer::InitDeviceMapper() {
    const std::string dm_path = "/devices/virtual/misc/device-mapper";
    bool found = false;
    auto dm_callback = [this, &dm_path, &found](const Uevent& uevent) {
        if (uevent.path == dm_path) {
            device_handler_->HandleUevent(uevent);
            found = true;
            return ListenerAction::kStop;
        }
        return ListenerAction::kContinue;
    };
    uevent_listener_.RegenerateUeventsForPath("/sys" + dm_path, dm_callback);
    if (!found) {
        LOG(INFO) << "device-mapper device not found in /sys, waiting for its uevent";
        Timer t;
        uevent_listener_.Poll(dm_callback, 10s);
        LOG(INFO) << "Wait for device-mapper returned after " << t;
    }
    if (!found) {
        LOG(ERROR) << "device-mapper device not found after polling timeout";
        return false;
    }
    return true;
}

ListenerAction BlockDevInitializer::HandleUevent(const Uevent& uevent,
                                                 std::set<std::string>* devices) {    
                                                
    // Ignore everything that is not a block device.
    if (uevent.subsystem != "block") {
        return ListenerAction::kContinue;
    }
    auto name = uevent.partition_name;
    
    if (name.empty()) {
        size_t base_idx = uevent.path.rfind('/');
        if (base_idx == std::string::npos) {
            return ListenerAction::kContinue;
        }
        name = uevent.path.substr(base_idx + 1);
    }
    auto iter = devices->find(name);
    if (iter == devices->end()) {
        return ListenerAction::kContinue;
    }
     LOG(INFO) << __PRETTY_FUNCTION__ << ": found partition: " << name;
    std::string::size_type platform_block_path = uevent.path.find("devices/platform/");
    std::string::size_type virtual_block_path = uevent.path.find(VirtualUeventPath);
    if(platform_block_path == std::string::npos && virtual_block_path == std::string::npos){
        //LOG(INFO) << "Do other block mount"
    }else if(android::fs_mgr::GetBootTypeVirtualDisk()){
        std::string::size_type uevent_pos;
        uevent_pos = uevent.path.find(VirtualUeventPath);
        if(uevent_pos == std::string::npos)  {
            return ListenerAction::kContinue;
        }        
    }else if(android::fs_mgr::GetBootTypeMultiDevice()){  
        std::string boot_devices_storagenode = android::fs_mgr::GetBootDevicesNode();
        std::string::size_type pcie_rk3568 = boot_devices_storagenode.find(PCIE_3568_NODE);
        std::string::size_type pcie_rk3566 = boot_devices_storagenode.find(PCIE_3566_NODE);
        std::string::size_type uevent_pos;
        if(pcie_rk3568 != std::string::npos){
            uevent_pos = uevent.path.find(REAL_PCIE_3568_PATH);
            if(uevent_pos == std::string::npos){
                return ListenerAction::kContinue;
            }
        }else if(pcie_rk3566 != std::string::npos){
            uevent_pos = uevent.path.find(REAL_PCIE_3566_PATH);
            if(uevent_pos == std::string::npos){
                return ListenerAction::kContinue;
            }
        }else{
            uevent_pos = uevent.path.find(boot_devices_storagenode);
            if(uevent_pos == std::string::npos)  {
                return ListenerAction::kContinue;
            }
        }
    }else{
        std::string android_boot_storagenode = android::fs_mgr::GetAndroidBootStoragemedia();
        std::string::size_type android_boot_storagenode_emmc_pos = android_boot_storagenode.find("emmc");
        std::string::size_type android_boot_storagenode_sd_pos = android_boot_storagenode.find("sd");
        std::string::size_type uevent_pos;
        if(android_boot_storagenode_emmc_pos != std::string::npos){
            uevent_pos = uevent.path.find("fe310000");
            if(uevent_pos == std::string::npos){
                return ListenerAction::kContinue;
            }
        }else if(android_boot_storagenode_sd_pos != std::string::npos){
            uevent_pos = uevent.path.find("fe2b0000");
            if(uevent_pos == std::string::npos){
                return ListenerAction::kContinue;
            }
        }

    }


    devices->erase(iter);
    device_handler_->HandleUevent(uevent);
    return devices->empty() ? ListenerAction::kStop : ListenerAction::kContinue;
}

bool BlockDevInitializer::InitDevices(std::set<std::string> devices) {
    auto uevent_callback = [&, this](const Uevent& uevent) -> ListenerAction {
        return HandleUevent(uevent, &devices);
    };
    uevent_listener_.RegenerateUevents(uevent_callback);
    // UeventCallback() will remove found partitions from |devices|. So if it
    // isn't empty here, it means some partitions are not found.
    if (!devices.empty()) {
        LOG(INFO) << __PRETTY_FUNCTION__
                  << ": partition(s) not found in /sys, waiting for their uevent(s): "
                  << android::base::Join(devices, ", ");
        Timer t;
        uevent_listener_.Poll(uevent_callback, 10s);
        LOG(INFO) << "Wait for partitions returned after " << t;
    }
    if (!devices.empty()) {
        LOG(ERROR) << __PRETTY_FUNCTION__ << ": partition(s) not found after polling timeout: "
                   << android::base::Join(devices, ", ");
        return false;
    }
    return true;
}

// Creates "/dev/block/dm-XX" for dm nodes by running coldboot on /sys/block/dm-XX.
bool BlockDevInitializer::InitDmDevice(const std::string& device) {
    const std::string device_name(basename(device.c_str()));
    const std::string syspath = "/sys/block/" + device_name;
    bool found = false;

    auto uevent_callback = [&device_name, &device, this, &found](const Uevent& uevent) {
        if (uevent.device_name == device_name) {
            LOG(VERBOSE) << "Creating device-mapper device : " << device;
            device_handler_->HandleUevent(uevent);
            found = true;
            return ListenerAction::kStop;
        }
        return ListenerAction::kContinue;
    };

    uevent_listener_.RegenerateUeventsForPath(syspath, uevent_callback);
    if (!found) {
        LOG(INFO) << "dm device '" << device << "' not found in /sys, waiting for its uevent";
        Timer t;
        uevent_listener_.Poll(uevent_callback, 10s);
        LOG(INFO) << "wait for dm device '" << device << "' returned after " << t;
    }
    if (!found) {
        LOG(ERROR) << "dm device '" << device << "' not found after polling timeout";
        return false;
    }
    return true;
}

}  // namespace init
}  // namespace android
