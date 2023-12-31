/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __CORE_FS_MGR_PRIV_BOOTCONFIG_H
#define __CORE_FS_MGR_PRIV_BOOTCONFIG_H

#include <sys/cdefs.h>
#include <string>
#include <utility>
#include <vector>

std::vector<std::pair<std::string, std::string>> fs_mgr_parse_boot_config(const std::string& cmdline);

bool fs_mgr_get_boot_config_from_kernel(const std::string& cmdline, const std::string& key,
                                        std::string* out_val);
bool fs_mgr_get_boot_config_from_kernel_cmdline(const std::string& key, std::string* out_val);
bool fs_mgr_get_boot_config_from_kernel_cmdline_without_andoridbootstring(const std::string& in_key, std::string* out_val);
bool fs_mgr_get_boot_config(const std::string& key, std::string* out_val);

#endif /* __CORE_FS_MGR_PRIV_BOOTCONFIG_H */
