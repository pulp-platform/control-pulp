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
// stencil header file

// matrix dimension

#define N 3
#define M 7

// result array


// N=2, N=2
// const int RESULT_STENCIL[M*N] = {11,13,13,13};


// N=3, M=7
const int RESULT_STENCIL[M*N] = {11, 19, 27, 35, 43, 51, 43, 25, 41, 54, 67, 80, 93, 79, 25, 45, 57, 69, 81, 93, 65};

// N=20,  M=20
/* const int RESULT_STENCIL[M*N] = {11, 19, 27, 35, 43, 51, 59, 67, 75, 83, 91, 99, 107, 115, 123, 131,  */
/* 			 139, 147, 155, 121, 25, 41, 54, 67, 80, 93, 106, 119, 132, 145,  */
/* 			 158, 171, 184, 197, 210, 223, 236, 249, 262, 209, 45,  70,  87,  */
/* 			 104, 121, 138, 155, 172, 189, 206, 223, 240, 257, 274, 291, 308,  */
/* 			 325, 342, 359, 284,  71, 107, 128, 149, 170, 191, 212, 233, 254,  */
/* 			 275, 296, 317, 338, 359, 380, 401, 422, 443, 464, 365, 103, 152,  */
/* 			 177, 202, 227, 252, 277, 302, 327, 352, 377, 402, 427, 452, 477,  */
/* 			 502, 527, 552, 577, 452, 141, 205, 234, 263, 292, 321, 350, 379,  */
/* 			 408, 437, 466, 495, 524, 553, 582, 611, 640, 669, 698, 545, 185,  */
/* 			 266, 299, 332, 365, 398, 431, 464, 497, 530, 563, 596, 629, 662,  */
/* 			 695, 728, 761, 794, 827, 644, 235, 335, 372, 409, 446, 483, 520,  */
/* 			 557, 594, 631, 668, 705, 742, 779, 816, 853, 890, 927, 964, 749,  */
/* 			 291, 412, 453, 494, 535, 576, 617, 658, 699, 740, 781, 822, 863,  */
/* 			 904, 945, 986, 1027, 1068, 1109, 860, 353, 497, 542, 587, 632, 677,  */
/* 			 722, 767, 812, 857, 902, 947, 992, 1037, 1082, 1127, 1172, 1217,  */
/* 			 1262,  977,  421,  590,  639,  688,  737,  786,  835,  884,  933,  */
/* 			 982, 1031, 1080, 1129, 1178, 1227, 1276, 1325, 1374, 1423, 1100,  */
/* 			 495,  691,  744,  797,  850,  903,  956, 1009, 1062, 1115, 1168,  */
/* 			 1221, 1274, 1327, 1380, 1433, 1486, 1539, 1592, 1229,  575,  800,  */
/* 			 857,  914,  971, 1028, 1085, 1142, 1199, 1256, 1313, 1370, 1427,  */
/* 			 1484, 1541, 1598, 1655, 1712, 1769, 1364,  661,  917,  978, 1039,  */
/* 			 1100, 1161, 1222, 1283, 1344, 1405, 1466, 1527, 1588, 1649, 1710,  */
/* 			 1771, 1832, 1893, 1954, 1505,  753, 1042, 1107, 1172, 1237, 1302,  */
/* 			 1367, 1432, 1497, 1562, 1627, 1692, 1757, 1822, 1887, 1952, 2017,  */
/* 			 2082, 2147, 1652,  851, 1175, 1244, 1313, 1382, 1451, 1520, 1589,  */
/* 			 1658, 1727, 1796, 1865, 1934, 2003, 2072, 2141, 2210, 2279, 2348,  */
/* 			 1805,  955, 1316, 1389, 1462, 1535, 1608, 1681, 1754, 1827, 1900,  */
/* 			 1973, 2046, 2119, 2192, 2265, 2338, 2411, 2484, 2557, 1964, 1065,  */
/* 			 1465, 1542, 1619, 1696, 1773, 1850, 1927, 2004, 2081, 2158, 2235,  */
/* 			 2312, 2389, 2466, 2543, 2620, 2697, 2774, 2129, 1181, 1622, 1703,  */
/* 			 1784, 1865, 1946, 2027, 2108, 2189, 2270, 2351, 2432, 2513, 2594,  */
/* 			 2675, 2756, 2837, 2918, 2999, 2300,  841, 1303, 1366, 1429, 1492,  */
/* 			 1555, 1618, 1681, 1744, 1807, 1870, 1933, 1996, 2059, 2122, 2185,  */
/* 			 2248, 2311, 2374, 1597}; */


// N=15,  M=25
 /* const int RESULT_STENCIL[M*N] = { 11,   19,   27,   35,   43,   51,   59,   67,   75,   83,   91,   99,  */
 /*  			  107,  115,  123,  131,  139,  147,  155,  163,  171,  179,  187,  195,  */
 /*  			  151,   25,   41,   54,   67,   80,   93,  106,  119,  132,  145,  158,  */
 /*  			  171,  184,  197,  210,  223,  236,  249,  262,  275,  288,  301,  314,  */
 /*  			  327,  259,   45,   70,   87,  104,  121,  138,  155,  172,  189,  206,  */
 /*  			  223,  240,  257,  274,  291,  308,  325,  342,  359,  376,  393,  410,  */
 /*  			  427,  444,  349,   71,  107,  128,  149,  170,  191,  212,  233,  254,  */
 /*  			  275,  296,  317,  338,  359,  380,  401,  422,  443,  464,  485,  506,  */
 /*  			  527,  548,  569,  445,  103,  152,  177,  202,  227,  252,  277,  302,  */
 /*  			  327,  352,  377,  402,  427,  452,  477,  502,  527,  552,  577,  602,  */
 /*  			  627,  652,  677,  702,  547,  141,  205,  234,  263,  292,  321,  350,  */
 /*  			  379,  408,  437,  466,  495,  524,  553,  582,  611,  640,  669,  698,  */
 /*  			  727,  756,  785,  814,  843,  655,  185,  266,  299,  332,  365,  398,  */
 /*  			  431,  464,  497,  530,  563,  596,  629,  662,  695,  728,  761,  794,  */
 /*  			  827,  860,  893,  926,  959,  992,  769,  235,  335,  372,  409,  446,  */
 /*  			  483,  520,  557,  594,  631,  668,  705,  742,  779,  816,  853,  890,  */
 /*  			  927,  964, 1001, 1038, 1075, 1112, 1149,  889,  291,  412,  453,  494,  */
 /*  			  535,  576,  617,  658,  699,  740,  781,  822,  863,  904,  945,  986,  */
 /*  			 1027, 1068, 1109, 1150, 1191, 1232, 1273, 1314, 1015,  353,  497,  542,  */
 /*  			  587,  632,  677,  722,  767,  812,  857,  902,  947,  992, 1037, 1082,  */
 /*  			 1127, 1172, 1217, 1262, 1307, 1352, 1397, 1442, 1487, 1147,  421,  590,  */
 /*  			  639,  688,  737,  786,  835,  884,  933,  982, 1031, 1080, 1129, 1178,  */
 /*  			 1227, 1276, 1325, 1374, 1423, 1472, 1521, 1570, 1619, 1668, 1285,  495,  */
 /*  			  691,  744,  797,  850,  903,  956, 1009, 1062, 1115, 1168, 1221, 1274,  */
 /*  			 1327, 1380, 1433, 1486, 1539, 1592, 1645, 1698, 1751, 1804, 1857, 1429,  */
 /*  			  575,  800,  857,  914,  971, 1028, 1085, 1142, 1199, 1256, 1313, 1370,  */
 /*  			 1427, 1484, 1541, 1598, 1655, 1712, 1769, 1826, 1883, 1940, 1997, 2054,  */
 /*  			 1579,  661,  917,  978, 1039, 1100, 1161, 1222, 1283, 1344, 1405, 1466,  */
 /*  			 1527, 1588, 1649, 1710, 1771, 1832, 1893, 1954, 2015, 2076, 2137, 2198,  */
 /*  			 2259, 1735,  481,  753,  801,  849,  897,  945,  993, 1041, 1089, 1137,  */
 /* 			 1185, 1233, 1281, 1329, 1377, 1425, 1473, 1521, 1569, 1617, 1665, 1713,  */
 /* 			 1761, 1809, 1217}; */
