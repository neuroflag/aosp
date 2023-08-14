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
#include <linux/loop.h>
#include <linux/fs.h>

#include "virtual_dev_initializer.h"

namespace android {
namespace init {

using android::base::Timer;
using namespace std::chrono_literals;

VirtualDevInitializer::VirtualDevInitializer() : uevent_listener_(16 * 1024 * 1024) {
    auto boot_devices = android::fs_mgr::GetBootDevices();
    device_handler_ = std::make_unique<DeviceHandler>(
            std::vector<Permissions>{}, std::vector<SysfsPermissions>{}, std::vector<Subsystem>{},
            std::move(boot_devices), false);
    realdev_blk = "/dev/block/real_blk";
    android::fs_mgr::GetVirtualDiskInfo(&realdev_blk_offset,&realdev_blk_size);
    android::fs_mgr::GetVirtualShareDiskInfo(&realdev_shareblk_offset,&realdev_shareblk_size);
}

ListenerAction VirtualDevInitializer::UeventMkDevices(const Uevent& uevent,
                                                 std::set<std::string>* devices) {
    if (uevent.subsystem != "block") {
        return ListenerAction::kContinue;
    }
    auto iter = devices->find(uevent.device_name);
    if (iter == devices->end()) {
        return ListenerAction::kContinue;
    }
    devices->erase(iter);
    device_handler_->HandleUevent(uevent);

    return devices->empty() ? ListenerAction::kStop : ListenerAction::kContinue;
}
bool VirtualDevInitializer::InitVirtualDevices() {

    std::string realdev_ueventpath = android::fs_mgr::GetBootDevicesNode();
    std::string::size_type pcie_rk3568 = realdev_ueventpath.find(PCIE_3568_NODE);
    std::string::size_type pcie_rk3566 = realdev_ueventpath.find(PCIE_3566_NODE);
    if(pcie_rk3568 != std::string::npos){
        realdev_ueventpath = REAL_PCIE_3568_PATH;
    }else if(pcie_rk3566 != std::string::npos){
        realdev_ueventpath = REAL_PCIE_3566_PATH;
    }
    if(!GetRealDevice(realdev_ueventpath)){
        LOG(ERROR)<<"VirtualDisk: Get Real Device Fail";
        return false;
    }
    std::set<std::string> devices;
    if(android::fs_mgr::GetBootTypeVirtualShareDisk()){
        devices.emplace("mmcblkshared1");
    }
    devices.emplace("mmcblkloop");
    auto uevent_callback = [&, this](const Uevent& uevent) -> ListenerAction {
            return UeventMkDevices(uevent, &devices);
    };
    uevent_listener_.RegenerateUevents(uevent_callback);
    if (!devices.empty()) {
        LOG(INFO) << ":Make Virtual Block Fail, waiting for their uevent(s): "
                  << android::base::Join(devices, ", ");
        Timer t;
        uevent_listener_.Poll(uevent_callback, 10s);
        LOG(INFO) << "Wait for Virtual Block returned after " << t;
    }
    if (!devices.empty()) {
        LOG(ERROR) << ": Make Virtual Block Fail after polling timeout: "
                   << android::base::Join(devices, ", ");
        return false;
    }
    return true;
}


ListenerAction VirtualDevInitializer::UeventGetRealDevice(const Uevent& uevent,
                                                std::string realdev_ueventpath) {

    
    if (uevent.subsystem != "block") {
        return ListenerAction::kContinue;
    }
    if(uevent.path.find(realdev_ueventpath) == std::string::npos){
        return ListenerAction::kContinue;
    }
    /* Get the true parent device */
    auto split_ueventpath = base::Split(uevent.path, "/");
    /*
    for(int i=0; i<(int)split_ueventpath.size(); i++){
        LOG(INFO) <<"debug "<<i<<" "<<split_ueventpath.at(i);
    }*/
    std::string get_parent_flag = split_ueventpath.at(split_ueventpath.size()-2);
    if(get_parent_flag == "block" || get_parent_flag == "nvme0"){
        /* Create parent blk first after determine */
        device_handler_->HandleUevent(uevent);

        /* Determine the true parent device */
        std::string get_parent_blk = "/dev/block/" + uevent.device_name;
        int ffd = open(get_parent_blk.c_str(),O_RDWR | O_CLOEXEC);
        if(ffd < 0){
            if(ffd > 0) close(ffd);        
             return ListenerAction::kContinue;  
        }else{
            realdev_blk = uevent.device_name;
            if(ffd > 0) close(ffd);
            return ListenerAction::kStop;           
        }      
    }
    return ListenerAction::kContinue;       
}
bool VirtualDevInitializer::GetRealDevice(std::string realdev_ueventpath){
    /* the set of realdev block device*/
    auto uevent_callback = [&, this](const Uevent& uevent) -> ListenerAction {    
        return UeventGetRealDevice(uevent, realdev_ueventpath);
    };
    uevent_listener_.RegenerateUevents(uevent_callback);

    if (realdev_blk == "/dev/block/real_blk") {
        LOG(INFO) << ":Real Block(main) not found, waiting for their uevent(s)";
        Timer t;
        uevent_listener_.Poll(uevent_callback, 10s);
        LOG(INFO) << "Wait for Real Block returned after " << t;
    }
    if (realdev_blk == "/dev/block/real_blk") {
        LOG(ERROR) << ":Real Block(main) not found after polling timeout 10s";
        return false;
    }
    return true;  
}
bool VirtualDevInitializer::AssociateDevices() {
    std::string realdev_blk_path("/dev/block/"+realdev_blk);
    std::string shareblk_loopname("share_"+realdev_blk);
    int ffd = -1,lfd = -1,sfd = -1;
    if (access(realdev_blk_path.c_str(), F_OK) == 0){
        ffd = open(realdev_blk_path.c_str(),O_RDWR | O_CLOEXEC);
    }else{
        return false;
    }
    if (access("/dev/block/mmcblkloop", F_OK) == 0) {
        struct loop_info64 loop_info;      
        lfd = open("/dev/block/mmcblkloop",O_RDWR | O_CLOEXEC); 
        ioctl(lfd, LOOP_GET_STATUS64, &loop_info);
        long long blk_offset = strtoll(realdev_blk_offset.c_str(), nullptr, 10) * 512;
        long long blk_size = strtoll(realdev_blk_size.c_str(), nullptr, 10) * 512;
        loop_info.lo_offset = blk_offset;
        loop_info.lo_sizelimit = blk_size;
        LOG(INFO) <<__func__<<": blk_offset = "<<loop_info.lo_offset<<" blk_size = "<<loop_info.lo_sizelimit;
        strncpy((char *)loop_info.lo_file_name, realdev_blk.c_str(), LO_NAME_SIZE);
        ioctl(lfd, LOOP_SET_FD, ffd);
        ioctl(lfd, LOOP_SET_STATUS64, loop_info);
        /* do blockdev --rereadpt*/
        ioctl(lfd, BLKRRPART);         
    }else{
        return false;
    }
    if(android::fs_mgr::GetBootTypeVirtualShareDisk()){
        if(access("/dev/block/mmcblkshared1", F_OK) == 0){
                struct loop_info64 loop_info;
                sfd = open("/dev/block/mmcblkshared1",O_RDWR | O_CLOEXEC); 
                ioctl(sfd, LOOP_GET_STATUS64, &loop_info);
                long long shareblk_offset = strtoll(realdev_shareblk_offset.c_str(), nullptr, 10) * 512;
                long long shareblk_size = strtoll(realdev_shareblk_size.c_str(), nullptr, 10) * 512;
                loop_info.lo_offset = shareblk_offset;
                loop_info.lo_sizelimit = shareblk_size;
                LOG(INFO) <<__func__<<": shareblk_offset = "<<loop_info.lo_offset<<" shareblk_size = "<<loop_info.lo_sizelimit;
                strncpy((char *)loop_info.lo_file_name, shareblk_loopname.c_str(), LO_NAME_SIZE);
                ioctl(sfd, LOOP_SET_FD, ffd);
                ioctl(sfd, LOOP_SET_STATUS64, loop_info);
                /* do blockdev --rereadpt*/
                ioctl(sfd, BLKRRPART);
        }else{
            return false;
        }
    }
    if (realdev_blk_path.c_str()) close(ffd);
    if (lfd != -1) close(lfd);
    if (sfd != -1) close(sfd);
    return true;
}

VirtualDevInitializer::~VirtualDevInitializer(){
    
}

}  // namespace init
}  // namespace android
