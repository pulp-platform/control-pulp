/*
 * Copyright (C) 2018 ETH Zurich and University of Bologna
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
 */

/* 
 * Mantainer: Luca Valente, luca.valente2@unibo.it
 */
RT_LOCAL_DATA int16_t g_stimuli[512] = {
0xD8F0,
0xD930,
0xD970,
0xD9B0,
0xD9F0,
0xDA30,
0xDA70,
0xDAB0,
0xDAF0,
0xDB30,
0xDB70,
0xDBB0,
0xDBF0,
0xDC30,
0xDC70,
0xDCB0,
0xDCF0,
0xDD30,
0xDD70,
0xDDB0,
0xDDF0,
0xDE30,
0xDE70,
0xDEB0,
0xDEF0,
0xDF30,
0xDF70,
0xDFB0,
0xDFF0,
0xE030,
0xE070,
0xE0B0,
0xE0F0,
0xE130,
0xE170,
0xE1B0,
0xE1F0,
0xE230,
0xE270,
0xE2B0,
0xE2F0,
0xE330,
0xE370,
0xE3B0,
0xE3F0,
0xE430,
0xE470,
0xE4B0,
0xE4F0,
0xE530,
0xE570,
0xE5B0,
0xE5F0,
0xE630,
0xE670,
0xE6B0,
0xE6F0,
0xE730,
0xE770,
0xE7B0,
0xE7F0,
0xE830,
0xE870,
0xE8B0,
0xE8F0,
0xE930,
0xE970,
0xE9B0,
0xE9F0,
0xEA30,
0xEA70,
0xEAB0,
0xEAF0,
0xEB30,
0xEB70,
0xEBB0,
0xEBF0,
0xEC30,
0xEC70,
0xECB0,
0xECF0,
0xED30,
0xED70,
0xEDB0,
0xEDF0,
0xEE30,
0xEE70,
0xEEB0,
0xEEF0,
0xEF30,
0xEF70,
0xEFB0,
0xEFF0,
0xF030,
0xF070,
0xF0B0,
0xF0F0,
0xF130,
0xF170,
0xF1B0,
0xF1F0,
0xF230,
0xF270,
0xF2B0,
0xF2F0,
0xF330,
0xF370,
0xF3B0,
0xF3F0,
0xF430,
0xF470,
0xF4B0,
0xF4F0,
0xF530,
0xF570,
0xF5B0,
0xF5F0,
0xF630,
0xF670,
0xF6B0,
0xF6F0,
0xF730,
0xF770,
0xF7B0,
0xF7F0,
0xF830,
0xF870,
0xF8B0,
0xF8F0,
0xF930,
0xF970,
0xF9B0,
0xF9F0,
0xFA30,
0xFA70,
0xFAB0,
0xFAF0,
0xFB30,
0xFB70,
0xFBB0,
0xFBF0,
0xFC30,
0xFC70,
0xFCB0,
0xFCF0,
0xFD30,
0xFD70,
0xFDB0,
0xFDF0,
0xFE30,
0xFE70,
0xFEB0,
0xFEF0,
0xFF30,
0xFF70,
0xFFB0,
0xFFF0,
0x0030,
0x0070,
0x00B0,
0x00F0,
0x0130,
0x0170,
0x01B0,
0x01F0,
0x0230,
0x0270,
0x02B0,
0x02F0,
0x0330,
0x0370,
0x03B0,
0x03F0,
0x0430,
0x0470,
0x04B0,
0x04F0,
0x0530,
0x0570,
0x05B0,
0x05F0,
0x0630,
0x0670,
0x06B0,
0x06F0,
0x0730,
0x0770,
0x07B0,
0x07F0,
0x0830,
0x0870,
0x08B0,
0x08F0,
0x0930,
0x0970,
0x09B0,
0x09F0,
0x0A30,
0x0A70,
0x0AB0,
0x0AF0,
0x0B30,
0x0B70,
0x0BB0,
0x0BF0,
0x0C30,
0x0C70,
0x0CB0,
0x0CF0,
0x0D30,
0x0D70,
0x0DB0,
0x0DF0,
0x0E30,
0x0E70,
0x0EB0,
0x0EF0,
0x0F30,
0x0F70,
0x0FB0,
0x0FF0,
0x1030,
0x1070,
0x10B0,
0x10F0,
0x1130,
0x1170,
0x11B0,
0x11F0,
0x1230,
0x1270,
0x12B0,
0x12F0,
0x1330,
0x1370,
0x13B0,
0x13F0,
0x1430,
0x1470,
0x14B0,
0x14F0,
0x1530,
0x1570,
0x15B0,
0x15F0,
0x1630,
0x1670,
0x16B0,
0x16F0,
0x1730,
0x1770,
0x17B0,
0x17F0,
0x1830,
0x1870,
0x18B0,
0x18F0,
0x1930,
0x1970,
0x19B0,
0x19F0,
0x1A30,
0x1A70,
0x1AB0,
0x1AF0,
0x1B30,
0x1B70,
0x1BB0,
0x1BF0,
0x1C30,
0x1C70,
0x1CB0,
0x1CF0,
0x1D30,
0x1D70,
0x1DB0,
0x1DF0,
0x1E30,
0x1E70,
0x1EB0,
0x1EF0,
0x1F30,
0x1F70,
0x1FB0,
0x1FF0,
0x2030,
0x2070,
0x20B0,
0x20F0,
0x2130,
0x2170,
0x21B0,
0x21F0,
0x2230,
0x2270,
0x22B0,
0x22F0,
0x2330,
0x2370,
0x23B0,
0x23F0,
0x2430,
0x2470,
0x24B0,
0x24F0,
0x2530,
0x2570,
0x25B0,
0x25F0,
0x2630,
0x2670,
0x26B0,
0x26F0,
0x2730,
0x2770,
0x27B0,
0x27F0,
0x2830,
0x2870,
0x28B0,
0x28F0,
0x2930,
0x2970,
0x29B0,
0x29F0,
0x2A30,
0x2A70,
0x2AB0,
0x2AF0,
0x2B30,
0x2B70,
0x2BB0,
0x2BF0,
0x2C30,
0x2C70,
0x2CB0,
0x2CF0,
0x2D30,
0x2D70,
0x2DB0,
0x2DF0,
0x2E30,
0x2E70,
0x2EB0,
0x2EF0,
0x2F30,
0x2F70,
0x2FB0,
0x2FF0,
0x3030,
0x3070,
0x30B0,
0x30F0,
0x3130,
0x3170,
0x31B0,
0x31F0,
0x3230,
0x3270,
0x32B0,
0x32F0,
0x3330,
0x3370,
0x33B0,
0x33F0,
0x3430,
0x3470,
0x34B0,
0x34F0,
0x3530,
0x3570,
0x35B0,
0x35F0,
0x3630,
0x3670,
0x36B0,
0x36F0,
0x3730,
0x3770,
0x37B0,
0x37F0,
0x3830,
0x3870,
0x38B0,
0x38F0,
0x3930,
0x3970,
0x39B0,
0x39F0,
0x3A30,
0x3A70,
0x3AB0,
0x3AF0,
0x3B30,
0x3B70,
0x3BB0,
0x3BF0,
0x3C30,
0x3C70,
0x3CB0,
0x3CF0,
0x3D30,
0x3D70,
0x3DB0,
0x3DF0,
0x3E30,
0x3E70,
0x3EB0,
0x3EF0,
0x3F30,
0x3F70,
0x3FB0,
0x3FF0,
0x4030,
0x4070,
0x40B0,
0x40F0,
0x4130,
0x4170,
0x41B0,
0x41F0,
0x4230,
0x4270,
0x42B0,
0x42F0,
0x4330,
0x4370,
0x43B0,
0x43F0,
0x4430,
0x4470,
0x44B0,
0x44F0,
0x4530,
0x4570,
0x45B0,
0x45F0,
0x4630,
0x4670,
0x46B0,
0x46F0,
0x4730,
0x4770,
0x47B0,
0x47F0,
0x4830,
0x4870,
0x48B0,
0x48F0,
0x4930,
0x4970,
0x49B0,
0x49F0,
0x4A30,
0x4A70,
0x4AB0,
0x4AF0,
0x4B30,
0x4B70,
0x4BB0,
0x4BF0,
0x4C30,
0x4C70,
0x4CB0,
0x4CF0,
0x4D30,
0x4D70,
0x4DB0,
0x4DF0,
0x4E30,
0x4E70,
0x4EB0,
0x4EF0,
0x4F30,
0x4F70,
0x4FB0,
0x4FF0,
0x5030,
0x5070,
0x50B0,
0x50F0,
0x5130,
0x5170,
0x51B0,
0x51F0,
0x5230,
0x5270,
0x52B0,
0x52F0,
0x5330,
0x5370,
0x53B0,
0x53F0,
0x5430,
0x5470,
0x54B0,
0x54F0,
0x5530,
0x5570,
0x55B0,
0x55F0,
0x5630,
0x5670,
0x56B0,
0x56F0,
0x5730,
0x5770,
0x57B0,
0x57F0,
0x5830,
0x5870,
0x58B0,
};
