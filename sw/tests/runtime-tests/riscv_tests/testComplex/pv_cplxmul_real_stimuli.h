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
#ifndef PV_CPLXMUL_REAL
#define PV_CPLXMUL_REAL
int cplxmul_opAr_[] = {
0x2058aacd,
0x99c1628,
0x3d1095b3,
0xb5a7317f,
0xe9785a99,
0x87435b57,
0x27f0048d,
0x626f1a89,
0x3bd9270d,
0xdbd3a924,
0x2019aaee,
0x4c19f22e,
0x3620b449,
0xa5941f54,
0x5e159c30,
0x46fdf426,
0xa4e7e6d,
0x14205099,
0x8218475e,
0xa1f8c9c8,
0x251f6b91,
0x701e293b,
0x43c44d10,
0x741dd28e,
0x7bb27f9d,
0x2a8c4ff0,
0x421f9bcb,
0x501476a5,
0x95f9783f,
0x146ff5a9,
0xe9cff40e,
0x727c5b6c,
0xac06f41e,
0x3b7c869c,
0x50642e1e,
0x99afdd74,
0x6af7584,
0xc29409ce,
0xdc5c4a74,
0xca1136b1,
0x86a1580e,
0xf3d9f49d,
0x6b42c8c0,
0x40ff43ed,
0x3996013b,
0xf54a556e,
0xb0db2366,
0x178467c6,
0xee625ce1,
0x8aff5300,
0x30753ec7,
0xb44b24af,
0x2e7d3724,
0x819876df,
0xad900ad9,
0x62e74baa,
0x40473431,
0xfcf256c0,
0x9aadab8a,
0xacc53df1,
0x9360d444,
0xf7aaa20f,
0x9d5443b,
0xa11c0f2e,
0x622ef838,
0x36ff2c1b,
0x50ca92a3,
0xc9c8eb4a,
0x62297f47,
0x8a204b60,
0x970a0fb9,
0x43eaed07,
0x43c7d752,
0x82dc40dc,
0x7ecede75,
0xb2b92fa1,
0xd1b1122e,
0x5669aa63,
0xb991db86,
0xd3bef785,
0x23a01bbf,
0xae630abd,
0xf607746b,
0xf3b2782b,
0xc38b5830,
0x67e97dd3,
0x6ada5a96,
0x31e8abd4,
0xecb0aea2,
0x8d17b4c4,
0xe4656b7e,
0x7dac3fd0,
0xea33b616,
0x919dd415,
0xcb9aa3c4,
0xbf83655b,
0x7019ef3b,
0x63a66de6,
0xe6116620,
0xbe515758,
};

int cplxmul_opBr_[] = {
0xd52ba99d,
0x433263a,
0xd20e4006,
0xeea8361b,
0xeadfbebf,
0x2a3d7bbf,
0xbb8fcf44,
0x855ba7ea,
0x7bffa5c2,
0x498616f8,
0x7c53479a,
0x36d50909,
0x76f0ec6c,
0x528d9a7b,
0xf1d35d01,
0x69e10de,
0x3718c6ff,
0x7050ad1,
0x40ec0927,
0xc7e6f5ad,
0x716c2bcb,
0xfb10f223,
0x9a0d2cfb,
0xd2bd806b,
0x9763160d,
0x5da71c43,
0x254c13b6,
0x23947c,
0x2ef79c3c,
0xf93e52b0,
0x638e20ca,
0xe7c9ffdc,
0xaae9aa6,
0xa3cdeece,
0xe47b4b9a,
0x77666bb3,
0x5dd755e7,
0x82e27276,
0xf2e1f7e4,
0xdf1559f,
0x71e28a44,
0x9dfa6b98,
0x14972f,
0x336b9e1d,
0xf0cd2f0b,
0x4fd62ca9,
0x2c86545b,
0xef02379f,
0x266e3734,
0x82ce92cf,
0xfe830ae9,
0x60d1fa34,
0x6caa5c5a,
0x543ee3b3,
0x39535f8b,
0xe9cf6230,
0xcdc8ab35,
0x426487ca,
0x25e7cddd,
0xfce875d0,
0xa27916b5,
0x6b104cbe,
0x845eceff,
0x6335a12,
0xece2aacc,
0xb5b58902,
0x8336eb65,
0x47bf1686,
0xfa3aefe1,
0x4f6c9bfd,
0xfe2d338d,
0xdec2393c,
0xc106cbf6,
0x99d32127,
0x96f7e6ed,
0xfda296bb,
0xe37a3970,
0x87068b3,
0xc2c567d8,
0x12a40ea3,
0x97a5afa7,
0x9b0cc859,
0xdee01adc,
0xabde2cb,
0x7ec9d91a,
0xca75a29,
0x93657cf6,
0x48eceb69,
0xc90546b,
0x3b59e2bf,
0x797ba387,
0xdcf838fb,
0xa1ae5cf5,
0xc4cde568,
0xf40b6474,
0x141bd771,
0x9fca8bb1,
0xa68daf28,
0x91f37eaa,
0x57c4b14a,
};

int cplxmul_opCr_[] = {
0x3bed10bc,
0x63230b73,
0x2966646b,
0x51428db3,
0x63419ed9,
0x2f0f4fd5,
0xbc5d69f,
0xe96f344,
0x3daf5c65,
0x390ab95f,
0x23002e9d,
0x6145ffed,
0x60e732da,
0x1ce26799,
0x34f8dce5,
0xfc18fcf,
0x4e310947,
0x48cac24d,
0x4796549c,
0x5c826dbb,
0x4ebeb658,
0x42682c0d,
0x38d481d7,
0x500d4209,
0x274dcbd7,
0x669630ff,
0x520ae896,
0x119b4a82,
0x14e2c2f2,
0x41d999e0,
0x7e38a246,
0x50cfd3af,
0x24fca554,
0x279f06b2,
0x22126162,
0x83e442d,
0x56ae5687,
0x2dd83801,
0x16d53771,
0x145db2ec,
0x66e2f160,
0x39d5660f,
0x75a3b2d9,
0x47ca243a,
0x56b7cda8,
0x2a9c8fbe,
0x578bb409,
0x24e8d6ef,
0x7367520b,
0x1f2208a5,
0x16b44ab,
0x42260864,
0x618a34b2,
0x3a3fc682,
0x12334a6d,
0x8d8008a,
0x20d5f781,
0x643e3304,
0x1a734b0c,
0x35b8ba73,
0x2617cce4,
0x18abed52,
0x6888e22,
0x4b147238,
0x404af404,
0x289aef84,
0x5352b665,
0x16f94a8b,
0x56732786,
0x6a27edd7,
0x2b56fd78,
0x3d5618e6,
0x23fd53e6,
0x20fab051,
0x5203d21,
0x7ab5218e,
0x4b974010,
0x5cabf12a,
0x1f9df87d,
0x3efe921b,
0x7bcdf9d0,
0x21093d28,
0x1249a7f,
0x5d582e82,
0x5b4903aa,
0x1357e4ed,
0x66302f0c,
0x7c1efb2b,
0x779617f1,
0xa37a18,
0x31d7b59f,
0x1dade4d5,
0x194f676b,
0x386043c1,
0x68c2570e,
0x599a5b6f,
0x60fb3346,
0x3c150d73,
0x7093a5fb,
0x376e5acc,
};

int cplxmul_opCResr_[] = {
0x3bed4452,
0x6323064d,
0x2966e0bf,
0x51420ad9,
0x6341ce18,
0x2f0f8025,
0xbc5139f,
0xe964c0d,
0x3dafaa7e,
0x390a0531,
0x2300b13c,
0x6145de6d,
0x60e7d949,
0x1ce22177,
0x34f8c1e5,
0xfc1fac4,
0x4e31c343,
0x48ca05b5,
0x479644f6,
0x5c82db28,
0x4ebe03e8,
0x4268ffdb,
0x38d4510d,
0x500d565a,
0x274d7b14,
0x6696f285,
0x520add4d,
0x119b9c41,
0x14e2c92e,
0x41d9fa66,
0x7e380e33,
0x50cf158e,
0x24fc106a,
0x279f3b27,
0x22122c85,
0x83e425f,
0x56ae49f7,
0x2dd8ccba,
0x16d5f7a1,
0x145d2a75,
0x66e21afe,
0x39d5ed1f,
0x75a32d2d,
0x47cab1f2,
0x56b7074a,
0x2a9c247c,
0x578b32db,
0x24e83037,
0x73672d58,
0x1f2246c1,
0x16b05ea,
0x4226379a,
0x618a0051,
0x3a3f38e9,
0x12332d04,
0x8d84b30,
0x20d5f6a4,
0x643eb01d,
0x1a733f16,
0x35b836ff,
0x2617a8df,
0x18abcea6,
0x688ef60,
0x4b140f46,
0x404a13d7,
0x289af6eb,
0x5352605e,
0x16f91abf,
0x5673f465,
0x6a270e3e,
0x2b5604d6,
0x3d560927,
0x23fd31e2,
0x20faace7,
0x5206ea0,
0x7ab5d766,
0x4b97fdd6,
0x5cabb446,
0x1f9dc0b6,
0x3efe0579,
0x7bcd0ba0,
0x2109baf6,
0x12415d9,
0x5d58e59c,
0x5b492115,
0x13574e5b,
0x6630b318,
0x7c1ef11b,
0x7796cc3b,
0xa34679,
0x31d7cc8a,
0x1dad3ecd,
0x194fba41,
0x3860d612,
0x68c2b2b8,
0x599aea03,
0x60fb637e,
0x3c150039,
0x70934ec3,
0x376ef753,
};

#endif