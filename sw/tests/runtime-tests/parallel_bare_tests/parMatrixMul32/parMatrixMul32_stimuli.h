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
const int m_a[] = {
830,
-456,
-926,
-662,
135,
-922,
-509,
995,
818,
595,
135,
-639,
-371,
-234,
842,
-1020,
-130,
949,
-174,
137,
-916,
179,
576,
-253,
133,
7,
-121,
920,
775,
-22,
7,
138,
445,
-308,
283,
657,
33,
-482,
948,
-352,
471,
-40,
498,
728,
-399,
-636,
50,
796,
-35,
1011,
-970,
-619,
411,
-959,
-152,
40,
624,
1016,
10,
-631,
-833,
621,
-795,
-66,
222,
872,
-149,
-952,
-71,
404,
-373,
811,
267,
763,
-662,
-953,
663,
-381,
724,
35,
141,
969,
741,
204,
-653,
-920,
-661,
-770,
-237,
309,
877,
-969,
-372,
-663,
-460,
711,
663,
-517,
-241,
704,
-557,
-791,
852,
-248,
640,
-454,
-995,
-362,
99,
465,
-974,
546,
-192,
411,
399,
-653,
367,
-964,
-890,
-617,
-322,
-916,
-181,
-781,
-892,
496,
-376,
996,
-446,
490,
397,
-31,
-233,
-293,
568,
-819,
-668,
-352,
917,
920,
581,
-533,
437,
-243,
465,
230,
729,
-509,
259,
-885,
206,
-854,
520,
240,
707,
-652,
-342,
-574,
467,
524,
698,
-660,
947,
-1,
-908,
220,
988,
-803,
-532,
474,
168,
-124,
-210,
454,
886,
-893,
-285,
-1007,
-866,
263,
369,
885,
-24,
-1015,
496,
-283,
222,
199,
-698,
279,
68,
-229,
941,
677,
-806,
-913,
558,
652,
629,
-338,
-959,
468,
-336,
-351,
-789,
-665,
716,
-582,
-508,
-489,
-119,
717,
269,
-322,
68,
400,
880,
4,
-33,
384,
-537,
720,
-653,
269,
-492,
281,
-873,
-224,
-289,
466,
-202,
-105,
-223,
137,
-283,
-796,
105,
-528,
-107,
-640,
507,
481,
572,
-411,
720,
163,
-537,
-698,
-154,
88,
765,
701,
925,
-634,
751,
304,
-837,
2,
-691,
307,
626,
-717,
-858,
-441,
79,
515,
783,
250,
946,
934,
151,
-385,
-788,
-102,
-818,
-422,
-728,
739,
822,
254,
-330,
836,
-200,
733,
-537,
-724,
-824,
-472,
322,
-995,
-763,
-214,
774,
713,
-266,
301,
699,
458,
-1004,
301,
425,
386,
787,
436,
60,
614,
-162,
-900,
657,
-970,
495,
830,
-620,
-411,
-982,
842,
502,
44,
-78,
740,
699,
-307,
894,
915,
524,
731,
687,
769,
-718,
825,
508,
952,
-68,
733,
305,
-505,
667,
675,
855,
221,
-510,
-164,
731,
-497,
247,
37,
-269,
858,
-664,
-523,
-449,
772,
205,
-350,
-286,
-871,
448,
-91,
350,
-182,
233,
-870,
884,
885,
826,
532,
429,
591,
-238,
-435,
71,
661,
192,
982,
-937,
282,
939,
107,
-648,
-237,
212,
748,
912,
-76,
-20,
-304,
-175,
-390,
-878,
-360,
-476,
439,
558,
552,
-510,
-120,
-106,
-959,
-575,
505,
-829,
16,
734,
-882,
848,
864,
-653,
905,
751,
-304,
64,
-262,
715,
281,
585,
65,
100,
-579,
678,
425,
883,
-198,
482,
-508,
477,
1010,
783,
-36,
737,
-702,
-171,
59,
773,
-348,
-573,
-275,
-415,
-967,
468,
-544,
-655,
-200,
-255,
-598,
-950,
229,
790,
892,
-795,
-71,
-693,
-615,
562,
-326,
-545,
226,
255,
840,
-202,
-160,
891,
791,
-669,
-195,
-733,
372,
937,
208,
970,
814,
45,
57,
943,
439,
763,
-132,
83,
-324,
857,
-846,
810,
-832,
251,
-866,
-129,
-118,
574,
102,
-141,
342,
-478,
733,
611,
-843,
975,
270,
-638,
-692,
-618,
388,
-434,
488,
-1009,
-237,
566,
925,
-596,
640,
378,
-30,
-267,
299,
-260,
-134,
615,
-628,
-966,
-436,
-111,
34,
-4,
687,
133,
-666,
167,
-1012,
422,
361,
604,
836,
190,
-939,
564,
137,
-563,
397,
692,
934,
907,
-182,
-539,
974,
176,
988,
24,
12,
-739,
-236,
-851,
-509,
814,
-523,
654,
-350,
-320,
-395,
-863,
130,
-725,
117,
-788,
-822,
-909,
812,
534,
-232,
1009,
-583,
-455,
-257,
791,
971,
53,
837,
423,
527,
889,
-378,
-39,
-572,
713,
-588,
862,
-608,
364,
46,
476,
928,
392,
-819,
-805,
-377,
-684,
234,
263,
-245,
-461,
23,
226,
504,
-167,
74,
794,
1022,
464,
538,
-713,
748,
332,
246,
-969,
-293,
77,
43,
-940,
-977,
-170,
-203,
274,
-20,
-467,
-820,
315,
461,
291,
953,
251,
-885,
1001,
413,
591,
684,
698,
-701,
553,
-808,
-799,
-42,
-148,
-512,
-71,
742,
193,
-778,
38,
14,
-360,
-172,
461,
94,
873,
777,
-516,
-236,
487,
923,
-148,
-611,
-555,
457,
600,
867,
-135,
-487,
221,
563,
-847,
-636,
-237,
-735,
-994,
281,
862,
506,
-996,
-613,
-551,
-606,
733,
-338,
-643,
536,
513,
285,
497,
99,
-439,
-258,
-609,
-712,
740,
-200,
910,
-845,
833,
-242,
-637,
-780,
-137,
-155,
263,
-895,
877,
-95,
453,
777,
-196,
576,
93,
-556,
-71,
-241,
987,
1012,
117,
-149,
-940,
-790,
330,
-559,
-170,
136,
-26,
-227,
153,
-937,
161,
-954,
-996,
-725,
242,
-369,
672,
474,
-181,
856,
863,
-419,
-279,
-1009,
8,
-695,
-834,
437,
-611,
-34,
-97,
637,
17,
-208,
288,
-826,
-29,
-828,
777,
-490,
240,
244,
-436,
-636,
-413,
-730,
-426,
-547,
-135,
453,
930,
357,
-926,
-448,
96,
-672,
-1003,
644,
172,
938,
189,
-892,
-628,
-806,
673,
-430,
684,
291,
625,
161,
-935,
-275,
840,
944,
886,
-28,
348,
-947,
431,
-96,
-638,
500,
-163,
1022,
-775,
-641,
-42,
-90,
-192,
568,
-845,
748,
-95,
-625,
-426,
656,
-48,
895,
791,
1009,
-830,
-442,
406,
771,
941,
337,
603,
-601,
712,
844,
-611,
-649,
-163,
-911,
833,
284,
-591,
-574,
-653,
-454,
-731,
-784,
-511,
-1005,
831,
900,
-878,
544,
-592,
717,
722,
460,
-76,
-572,
726,
306,
990,
931,
320,
-513,
-920,
-578,
149,
115,
-961,
584,
796,
577,
-850,
973,
-661,
-935,
-249,
134,
-942,
-19,
269,
972,
-810,
-678,
976,
991,
488,
-300,
-295,
573,
403,
590,
-518,
341,
135,
710,
-381,
807,
668,
-300,
828,
-205,
-710,
498,
-786,
-657,
152,
413,
97,
261,
784,
289,
-936,
-858,
119,
-72,
702,
-2,
-437,
147,
-968,
-932,
-463,
-880,
938,
-574,
-177,
-932,
521,
333,
713,
-855,
-549,
585,
-672,
29,
739,
115,
-875,
-140,
-812,
-30,
-898,
-528,
-1012,
-534,
585,
-419,
273,
-551,
-452,
642,
836,
881,
235,
-450,
-1009,
-480,
-508,
844,
755,
-851,
-28,
-363,
-727,
590,
-111,
-764,
-364,
-167,
-409,
291,
-253,
-718,
-943,
-47,
755,
316,
-1012,
-456,
212,
19,
358,
-732,
665,
659,
445,
706,
-723,
-471,
266,
740,
-207,
-164,
446,
418,
482,
986,
-382,
126,
-920,
260,
-488,
929,
515,
969,
-725,
-57,
-106,
-146,
-454,
58,
706,
-297,
-233,
262,
-749,
-498,
660,
-657,
-279,
136,
401,
-330,
569,
-159,
774,
816,
484,
-333,
642,
-460,
};

const int m_b[] = {
739,
-691,
-674,
-272,
816,
-147,
760,
-56,
581,
-550,
763,
539,
251,
-2,
-701,
579,
-53,
-241,
699,
831,
752,
505,
715,
-131,
24,
-268,
778,
921,
368,
-430,
-711,
-781,
678,
-746,
-755,
222,
477,
-568,
140,
201,
-696,
-992,
-201,
964,
-784,
-532,
-863,
1014,
-642,
6,
589,
924,
662,
238,
485,
859,
808,
841,
-192,
91,
42,
45,
355,
293,
-182,
34,
-883,
915,
-414,
736,
613,
418,
-202,
437,
-229,
-564,
-250,
-125,
-233,
-397,
331,
447,
-41,
975,
853,
573,
-475,
-79,
-932,
37,
-367,
-244,
300,
5,
-188,
595,
934,
122,
-76,
-446,
703,
-68,
214,
963,
-160,
529,
98,
616,
161,
476,
-808,
262,
49,
646,
-647,
-835,
-706,
697,
-26,
-858,
496,
452,
875,
479,
73,
-387,
512,
85,
58,
420,
-167,
708,
-847,
408,
-254,
62,
700,
-576,
-850,
18,
186,
-940,
519,
906,
559,
480,
-1022,
-393,
-726,
-219,
204,
-231,
899,
-998,
350,
-795,
180,
-36,
261,
315,
-565,
-707,
864,
-279,
859,
-993,
37,
-841,
287,
-613,
693,
626,
887,
-781,
-779,
415,
610,
759,
-655,
-999,
521,
569,
726,
761,
330,
-513,
797,
975,
-883,
-718,
-748,
-237,
-892,
942,
715,
63,
-272,
-368,
738,
177,
267,
-703,
991,
1002,
-916,
143,
879,
-233,
-478,
66,
39,
-516,
803,
-341,
997,
770,
-810,
-577,
-244,
1005,
190,
593,
530,
-243,
-41,
-801,
16,
45,
-834,
-722,
-265,
-64,
1011,
-397,
-88,
-228,
179,
22,
-295,
-296,
549,
373,
-502,
1022,
29,
824,
-523,
969,
-973,
-402,
-955,
-119,
-294,
489,
-905,
806,
-864,
-41,
-735,
-15,
-338,
990,
-294,
403,
485,
248,
468,
389,
-735,
999,
-848,
-263,
715,
550,
-750,
-207,
-407,
-77,
-833,
-939,
117,
624,
-891,
13,
785,
547,
-898,
622,
141,
95,
-133,
-341,
880,
829,
172,
28,
702,
527,
-186,
-61,
-721,
-121,
-862,
-990,
-94,
-657,
-131,
429,
760,
-779,
504,
1012,
-17,
800,
892,
-163,
309,
-700,
20,
808,
-198,
0,
331,
735,
259,
479,
820,
-450,
3,
-736,
391,
1002,
81,
-377,
-387,
-160,
-909,
1014,
881,
-955,
-206,
-369,
-672,
2,
842,
-835,
427,
-392,
-917,
31,
712,
-570,
586,
-59,
538,
-432,
-470,
499,
-528,
-969,
1011,
-101,
-331,
-961,
515,
-301,
119,
116,
-570,
919,
961,
707,
-705,
998,
969,
205,
113,
303,
52,
-952,
-268,
-743,
282,
359,
-826,
140,
-936,
-900,
-682,
400,
379,
624,
-72,
264,
-887,
29,
-1005,
-97,
-168,
-769,
719,
450,
178,
-37,
783,
-857,
-237,
-409,
845,
914,
-877,
175,
-717,
191,
-713,
-365,
-672,
775,
516,
-656,
-506,
989,
573,
-59,
523,
-392,
-374,
891,
408,
-115,
488,
-3,
-401,
-2,
-102,
809,
-284,
833,
237,
60,
-77,
294,
431,
940,
-462,
-309,
-988,
331,
-197,
614,
-829,
1012,
545,
-708,
598,
216,
297,
643,
-605,
975,
-878,
259,
384,
550,
-98,
672,
-452,
982,
-586,
-301,
919,
-984,
-646,
-973,
124,
790,
648,
-683,
330,
-724,
77,
647,
442,
11,
-790,
585,
517,
434,
-795,
-316,
50,
235,
-182,
-355,
505,
-292,
-298,
-659,
391,
571,
-848,
-870,
-869,
-987,
105,
-786,
-791,
-550,
448,
565,
-610,
-910,
694,
144,
-50,
891,
795,
691,
626,
-461,
-354,
-484,
-844,
582,
626,
-82,
646,
762,
36,
-671,
120,
-874,
685,
1017,
722,
11,
-477,
-19,
283,
-980,
976,
-341,
59,
-495,
-679,
887,
-890,
-167,
633,
412,
-225,
114,
238,
754,
685,
-522,
565,
983,
159,
-678,
202,
-811,
-902,
950,
560,
-849,
-588,
0,
-939,
199,
-214,
-575,
-703,
-689,
1019,
799,
-478,
435,
499,
686,
-1002,
343,
-786,
858,
65,
273,
562,
-645,
218,
-302,
68,
-700,
-760,
-512,
-899,
-6,
661,
-507,
1016,
-679,
325,
314,
601,
-280,
-22,
-761,
238,
779,
-260,
118,
-836,
801,
62,
-382,
-187,
233,
285,
890,
978,
888,
-551,
901,
-31,
170,
44,
850,
-288,
107,
882,
-786,
-718,
936,
761,
-796,
374,
-142,
868,
-410,
579,
-122,
-14,
-1018,
-858,
419,
-393,
-508,
-396,
454,
-857,
-576,
-147,
-222,
-90,
-263,
-358,
-810,
178,
737,
-966,
40,
-246,
683,
916,
-843,
-633,
849,
-101,
744,
-375,
181,
-314,
372,
58,
404,
-428,
-894,
-743,
694,
-293,
-128,
-604,
-734,
-228,
325,
-1018,
-150,
202,
-808,
-610,
741,
-978,
191,
-57,
458,
-29,
169,
193,
-43,
1019,
963,
-302,
318,
-229,
-900,
-543,
-16,
-512,
497,
-455,
-970,
435,
-186,
819,
-860,
790,
44,
642,
398,
-730,
-109,
-42,
651,
-278,
-744,
411,
-69,
-276,
-955,
-36,
660,
-396,
-471,
892,
-46,
147,
-312,
167,
-46,
-456,
827,
-468,
314,
-244,
690,
47,
569,
979,
-1005,
689,
-748,
629,
-896,
13,
674,
-814,
-520,
479,
-691,
704,
-153,
-553,
146,
-757,
547,
-133,
597,
730,
394,
368,
-544,
-222,
884,
860,
-459,
502,
-648,
740,
-522,
912,
637,
672,
711,
171,
912,
657,
98,
-96,
-53,
-495,
-265,
-962,
484,
-138,
-618,
316,
-119,
489,
951,
45,
-372,
987,
-90,
741,
29,
-756,
-147,
640,
-539,
376,
-875,
680,
-261,
988,
-371,
724,
999,
-101,
-617,
397,
-1020,
983,
204,
74,
-615,
626,
113,
-776,
35,
321,
488,
-614,
-847,
-306,
-237,
15,
393,
-148,
603,
692,
-713,
483,
-332,
-51,
-226,
444,
-564,
-161,
411,
598,
-431,
-583,
938,
-607,
448,
614,
-337,
-11,
-962,
127,
425,
-818,
-587,
710,
-698,
570,
-355,
-900,
165,
-358,
229,
52,
802,
-1022,
52,
-604,
86,
328,
353,
-940,
-256,
-578,
-912,
463,
-1006,
777,
255,
515,
-899,
-34,
975,
-30,
-97,
-815,
316,
-923,
-324,
728,
722,
-99,
-86,
687,
-636,
-535,
761,
-759,
-723,
-850,
23,
-16,
-608,
242,
736,
368,
916,
892,
215,
-785,
597,
587,
-33,
382,
-147,
-352,
-537,
-738,
472,
-844,
367,
408,
-742,
282,
451,
427,
-696,
227,
374,
753,
-971,
735,
-768,
941,
888,
-854,
166,
-590,
-809,
-187,
633,
-607,
241,
215,
-516,
-345,
-135,
-51,
215,
-690,
-807,
-595,
607,
-574,
-323,
-765,
-3,
-970,
-316,
557,
985,
983,
-368,
-763,
-316,
943,
284,
-341,
-24,
892,
335,
498,
-241,
982,
-619,
560,
541,
267,
-458,
-264,
-661,
476,
695,
142,
-306,
157,
451,
180,
408,
576,
179,
-56,
546,
409,
965,
-73,
-140,
903,
984,
146,
890,
461,
-173,
21,
-286,
561,
949,
-653,
1019,
-813,
666,
-5,
412,
-55,
438,
-113,
426,
};

const int m_exp[] = {
162957,
806616,
-3843440,
425896,
2155437,
-822680,
-787915,
621747,
2923873,
1244247,
-97532,
610424,
-202711,
3997637,
-1726865,
619432,
907569,
-1548516,
-94406,
1429714,
728504,
-1334534,
-1711394,
-60696,
-1270495,
42411,
-393126,
-1426839,
766595,
196776,
-1218293,
805161,
1753338,
19573,
1743399,
1305905,
2305550,
691613,
2936488,
-2499956,
2011437,
-576528,
4857673,
-522113,
1643246,
2107051,
1243612,
1226992,
-579490,
-2007336,
735201,
215903,
-2371734,
-604993,
-2228234,
-2776681,
-2711032,
-1272536,
-2272696,
-421571,
1355942,
88773,
2385693,
-574961,
-2571513,
636093,
-458404,
546496,
2480672,
155697,
101546,
-1189865,
1932128,
3516193,
-155025,
758029,
-2133330,
292469,
259193,
1783456,
3153657,
-4306725,
-1756271,
5321880,
3387043,
-2499824,
-1354163,
3589105,
-822661,
-787877,
-1296774,
-53917,
1000889,
-2479239,
522736,
1610045,
-1888070,
1262549,
2391084,
-2993663,
880432,
2253879,
-738882,
2578797,
-91861,
3546872,
1784236,
-1334715,
-370233,
4225505,
523924,
-1638264,
496623,
-4977506,
-932716,
2456108,
-1528737,
619156,
-1996122,
-559761,
-3729495,
2583519,
-688975,
2327479,
538691,
-216394,
-624983,
3287485,
-948798,
938455,
1079709,
2579776,
560856,
71743,
2473123,
-1855915,
982427,
-322892,
-1051648,
279832,
928945,
-563243,
1512085,
2329787,
-291655,
219971,
2918255,
-418247,
1076304,
-260668,
1590893,
96628,
459386,
-535583,
20579,
-2682940,
250239,
-1121829,
4796976,
-1449568,
-884030,
-1012825,
-557312,
-660713,
2703126,
-1000609,
4119713,
-2261740,
568061,
-807901,
571882,
4117378,
-3168209,
1856661,
-1360182,
-275958,
-1371570,
1334388,
1163735,
902800,
1090827,
2127115,
1805917,
1394998,
-1897442,
-1552564,
4831224,
5873204,
862717,
-1328233,
-481290,
-3881988,
1967283,
-3210455,
194601,
3623555,
4233139,
-5588664,
460768,
-2153116,
1640966,
-1574766,
4489450,
2035547,
591125,
-112588,
-677732,
3516302,
-1487398,
-1392413,
-549940,
-122305,
1734974,
-1296448,
3345459,
3278967,
-403583,
-2476952,
3103106,
3668860,
876310,
-1372508,
1606576,
-1242432,
-17363,
-536767,
-957924,
-840288,
1387793,
-1263453,
-1580935,
1255033,
-3199921,
-582299,
-3536182,
8014,
694206,
-868893,
-733959,
691991,
1905970,
-2105517,
-611054,
-2008274,
1869390,
781905,
3204537,
846463,
582367,
1557785,
970604,
-232359,
-2832418,
362033,
-287796,
-295851,
115014,
2136015,
-355990,
-3623476,
-2897332,
3725302,
243172,
-1681724,
-385794,
472207,
-2443791,
873057,
-2272285,
-1444140,
127766,
-1695914,
-2155654,
1292115,
376558,
-2959312,
-1679103,
-1846952,
-2678017,
-3209721,
4578141,
3381475,
-115092,
-277905,
-1622304,
444339,
31506,
-1835191,
-1095261,
1184692,
-1320035,
-768825,
-24927,
-441171,
-2206653,
3016395,
1322957,
2359340,
-2045739,
-2535559,
2589403,
488750,
-352073,
-1583926,
2559165,
-236263,
-2305301,
-1143355,
-811472,
157863,
2734081,
-3540908,
-3266165,
3356957,
-2546548,
120541,
-614357,
-321236,
-4262586,
3134062,
69010,
1673410,
578416,
1494750,
1401048,
1434942,
2202613,
-1168868,
4234494,
1083346,
1136258,
2189311,
2610004,
981866,
-1297232,
590461,
-1470399,
182048,
-987329,
-815848,
4511995,
3218281,
1891474,
2139246,
-1953818,
760442,
4370650,
-155141,
141023,
-3911135,
704029,
1270803,
-1160789,
639262,
-140142,
492202,
-3552999,
726790,
730943,
294228,
1626723,
-2909194,
-54567,
1406030,
-511915,
14996,
2901103,
202415,
-765411,
3954449,
1634496,
765702,
-1670288,
-1746308,
-236974,
402163,
2225940,
-4092672,
-487529,
458477,
-850359,
2502080,
-1833536,
-2648383,
469522,
-2065549,
-1110710,
-1161586,
-1598119,
312213,
-3414626,
2809732,
-1270950,
231301,
948652,
-5241164,
-142131,
-101551,
-924256,
-4661011,
1373376,
-384970,
-1771026,
2352833,
-1508015,
-1567875,
-77896,
-298333,
-2109926,
1841301,
-1841526,
463269,
-1579323,
3378298,
-1686942,
2286923,
-1725730,
888978,
-132747,
1196962,
765073,
2561682,
3394037,
686372,
3609261,
1739268,
-1632029,
223041,
7802,
1613144,
-1505669,
236211,
2125044,
-287008,
1433003,
-3433392,
2365446,
-1739067,
-1742567,
572370,
387905,
137241,
-205103,
-3092809,
3403304,
-626777,
1682114,
208043,
-3166100,
-494447,
-1814690,
-1598424,
-5459778,
2167916,
-1761705,
425344,
1806134,
-1823602,
-846377,
-1890539,
-462188,
-1485705,
101051,
-3918737,
1878057,
527232,
-3992037,
1295344,
76046,
-3594473,
165856,
-209224,
2988651,
1205027,
-128456,
-688247,
-1858378,
1319809,
-654178,
1197795,
2203611,
429127,
-153254,
-1002844,
-73001,
-777076,
624879,
-749349,
517398,
1047706,
-483949,
21723,
-2834312,
575021,
2162429,
1157482,
251420,
165568,
3589958,
1166415,
971492,
-791336,
221991,
1202426,
-486702,
-2021786,
-998812,
1488325,
875139,
2095034,
-3432500,
-3200858,
708188,
-1230553,
-1027252,
3204443,
1541304,
1441524,
2393495,
240432,
154630,
711539,
1546622,
-3606712,
2329971,
2037395,
488837,
-1149213,
1004476,
-5353576,
-1445258,
1830702,
2334502,
-1027586,
-786918,
-830800,
-5014319,
603373,
-2356785,
391822,
-559514,
832315,
854580,
-274568,
-852866,
-1829693,
-224252,
-442985,
-511368,
-2738731,
785781,
1213180,
-452741,
-1912617,
2501858,
1190107,
374756,
4063611,
-3167900,
590894,
-843960,
-1329399,
1982532,
-1501664,
-480615,
978312,
-776372,
-758612,
-342051,
1297314,
-1330216,
2192151,
514261,
1924564,
-1450262,
-1368891,
709611,
910433,
10007,
379287,
-927492,
2341527,
-614574,
213605,
1313660,
-511351,
2179833,
-3229739,
970187,
24229,
-563469,
-290337,
-1413501,
-1110798,
1687978,
-1070551,
667748,
-378655,
1343272,
-1179176,
465076,
1061328,
-725446,
-632171,
-3115122,
126962,
679313,
468649,
-54748,
-1693703,
-1504854,
1706614,
1984152,
-147089,
-677246,
-2363197,
-958222,
-1058809,
2137431,
-1457226,
1613151,
-1096760,
-62862,
-1303936,
-470334,
-677938,
-3350678,
686828,
-3218401,
-2491773,
823333,
-3515802,
-521386,
-745281,
1801059,
-364988,
262475,
-1628907,
4610600,
-1790296,
1637070,
-111930,
695554,
631793,
-58009,
879861,
-396942,
-3491554,
-2099070,
-1427409,
274894,
3138017,
-3984461,
-1428478,
1281318,
1326242,
-2425032,
3375811,
1883570,
986169,
-2026937,
851459,
-2948484,
887635,
1664977,
-787389,
192262,
-199263,
2417949,
1357190,
-675828,
-2140148,
-1992713,
-812035,
-189832,
-1687171,
-1455287,
-1968142,
-95663,
1491237,
-97044,
-1478691,
-818723,
540642,
-1935376,
-2011417,
-1496601,
-2432622,
-1711594,
1082040,
4280682,
-245468,
2632647,
-2126102,
4408049,
1347238,
1881351,
2741419,
275662,
39237,
-90511,
293945,
1132383,
-38055,
1318991,
-285413,
-1197211,
758713,
5302556,
-910446,
-1192408,
1951665,
599939,
1684692,
-905949,
467600,
-1781331,
2472257,
-4560636,
2121801,
7702,
-953875,
810154,
2235783,
-1721404,
1466909,
823131,
257449,
-467541,
2196156,
1231438,
-1055257,
1235031,
-2824591,
1407798,
4017064,
496444,
-2144864,
172928,
-780962,
-1351533,
-770027,
-2035068,
-10361,
2252778,
-21797,
-3779047,
-3409395,
494668,
-331048,
-331324,
-355901,
-429937,
-109578,
2141215,
3507397,
-475137,
1741184,
2711387,
1735523,
-546046,
-104827,
1803323,
-1088839,
10836,
-1512582,
-1126855,
1130557,
-3863013,
-1429454,
-2311546,
988010,
-34163,
-2855425,
668343,
-504504,
-875488,
29458,
-86216,
288365,
-434627,
3493242,
-130938,
-1988278,
3075370,
953334,
-4261726,
691990,
-344124,
1873383,
-2948777,
-37293,
-6201594,
194461,
-3063704,
3296851,
-361236,
2148972,
-1689659,
-1587584,
-1973610,
136604,
864708,
-208814,
-5210513,
-2382198,
-938078,
-623312,
2134892,
20690,
-328389,
425817,
1494259,
341657,
2041202,
215726,
1999270,
4556161,
-1534970,
846236,
-1779277,
487163,
-2503709,
-881316,
641969,
-1533604,
-1307702,
-28391,
2386501,
1889399,
-2798701,
-1452890,
-2458612,
1135665,
-822540,
-1224665,
-3168295,
3202581,
-1833843,
2028127,
316317,
2771444,
-1969294,
-1862180,
-1846963,
3288593,
-1058949,
-4301372,
-2270312,
-1814302,
-2507256,
2304887,
-1357358,
-398110,
2224556,
-3014825,
-1386326,
3381979,
1996942,
1199292,
2726576,
-2409907,
-651850,
619670,
-1475982,
2412631,
-1348814,
-1226204,
39236,
1327167,
-1771649,
547246,
-147406,
2114780,
-861050,
-369180,
-1802507,
-1044212,
1027808,
-268747,
898922,
-1231614,
-2479622,
3128666,
2129144,
-2150987,
743,
1381784,
1709971,
3159903,
-1724033,
1467305,
-1549225,
-1149491,
-1241667,
1923850,
-1031013,
-1854871,
5195468,
-1312499,
-1683183,
-2852635,
1375570,
-2626830,
252623,
-2799957,
416997,
-768714,
521710,
-1525373,
1399518,
781524,
1078645,
481978,
-169425,
-595560,
-4627513,
1999980,
-1414190,
-912128,
-464019,
-1908668,
-1299171,
2822564,
-3299799,
1134772,
-717124,
-1175570,
1450585,
-1338075,
886999,
352573,
4223081,
247130,
1087502,
-1634036,
-1292452,
595147,
2611183,
-1018214,
3045670,
25600,
527454,
-410755,
-1575051,
-4673725,
2022228,
342427,
-411410,
-3969320,
-1582114,
-196149,
417835,
-2069373,
1140594,
-1982957,
-1168881,
-1680247,
3341440,
-2163154,
644414,
899481,
-3068320,
1730507,
2120763,
800244,
-1950761,
2797422,
999558,
4224011,
267319,
-2575349,
1303602,
3822345,
-1179231,
-83832,
1094373,
-2890364,
-2847299,
1097183,
270678,
-1041859,
-243475,
-2372503,
-983943,
2643567,
-1140781,
-1564791,
921293,
-2492580,
412995,
3308919,
-69183,
-1264313,
292080,
-1901711,
-2160028,
-1433855,
-1297772,
1209393,
-760271,
-1505265,
-2822187,
-750104,
1326341,
-2406512,
-2811558,
634457,
2153554,
1165807,
-1251857,
-2639503,
-2455102,
-397631,
988547,
-2515259,
4482079,
763623,
559995,
-1070705,
-2788379,
545963,
-1318607,
-896632,
};

#define SIZE 32
__attribute__ ((section(".heapsram"))) int g_mA[SIZE][SIZE];
__attribute__ ((section(".heapsram"))) int g_mB[SIZE][SIZE];
__attribute__ ((section(".heapsram"))) int g_mC[SIZE][SIZE];
__attribute__ ((section(".heapsram"))) int g_mB_tmp[SIZE][SIZE];
