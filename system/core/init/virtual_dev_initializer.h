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

#include <memory>
#include <set>
#include <string>

#include "devices.h"
#include "uevent_listener.h"

#define VirtualUeventPath "virtual/block/mmcblkloop"

namespace android {
namespace init {

class VirtualDevInitializer final {
  public:
    VirtualDevInitializer();
    ~VirtualDevInitializer();
    bool InitVirtualDevices();
    bool AssociateDevices();
    bool GetRealDevice(std::string realdev_ueventpath);
  private:
    std::string realdev_blk; /*May be not one but tow,need to figure out*/

    std::string realdev_blk_offset;
    std::string realdev_blk_size;

    std::string realdev_shareblk_offset;
    std::string realdev_shareblk_size;

    ListenerAction UeventMkDevices(const Uevent& uevent, std::set<std::string>* devices);
    ListenerAction UeventGetRealDevice(const Uevent& uevent, std::string realdev_ueventpath);
    std::unique_ptr<DeviceHandler> device_handler_;
    UeventListener uevent_listener_;
};

}  // namespace init
}  // namespace android
