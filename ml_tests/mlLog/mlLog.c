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
 * Mantainer: Luca Valente luca.valente2@unibo.it
 */
/////////////////////////////////////////////////////////
// includes
/////////////////////////////////////////////////////////
#include "mlLog.h"
#include "math_fns.h"
#include "pulp.h"

/////////////////////////////////////////////////////////
// shared globals
/////////////////////////////////////////////////////////

  RT_LOCAL_DATA static const float fv0[400] = { 89.9738922F, 66.189743F, 77.4553F, 43.9656792F,
    81.6032867F, 25.3587627F, 26.9942513F, 50.7894249F, 91.7021713F, 59.2133179F,
    52.5731506F, 74.839447F, 70.1338959F, 63.1093102F, 13.4191017F, 14.31075F,
    30.415062F, 7.3929143F, 70.2335129F, 99.4281F, 94.7875214F, 38.8088226F,
    71.5575104F, 97.7270279F, 91.6618652F, 90.0910873F, 85.5291901F, 75.0516052F,
    70.093132F, 41.2426376F, 41.5050621F, 3.88008094F, 58.7252655F, 7.56845F,
    70.1915131F, 31.8804893F, 42.7131882F, 38.5091515F, 29.9700165F, 31.5833874F,
    64.8916626F, 62.869606F, 79.215538F, 41.0702858F, 54.9167366F, 50.5589943F,
    23.2268887F, 89.4408493F, 93.7856216F, 45.2773857F, 73.5679779F, 89.1345749F,
    0.150142446F, 92.7815552F, 25.4968033F, 13.267169F, 45.6808357F, 77.4178F,
    31.9661655F, 58.5629654F, 38.2435722F, 0.458555788F, 5.11984F, 93.2144089F,
    76.4024124F, 44.3201752F, 75.3020554F, 23.4649487F, 68.6422729F, 19.0581379F,
    71.4824829F, 56.4980812F, 20.4976444F, 70.7688293F, 45.2124825F, 16.7774677F,
    97.6339951F, 10.8988123F, 91.6488113F, 7.40460587F, 5.69761658F, 59.0466232F,
    25.8443356F, 69.6690292F, 23.0113945F, 17.2221813F, 30.9389801F, 86.8216782F,
    71.5825882F, 47.4478073F, 89.4826584F, 59.1523F, 75.2779617F, 45.7180901F,
    78.4125824F, 94.2332077F, 55.3202209F, 79.5286179F, 36.7777138F, 83.3184204F,
    40.4074898F, 51.1991196F, 43.4081535F, 79.4233322F, 20.110323F, 60.6883278F,
    52.6181335F, 34.3373718F, 72.6405411F, 77.3120728F, 22.3641186F, 97.8585F,
    46.5118904F, 34.2477913F, 1.67930758F, 31.2774677F, 35.0329323F, 26.8849812F,
    78.1406937F, 43.4250565F, 5.5767417F, 26.7769852F, 18.0195656F, 71.1427689F,
    78.0236206F, 19.2247143F, 25.1562977F, 88.0416946F, 89.772049F, 48.7811317F,
    77.8435745F, 52.3360596F, 83.9105835F, 13.7854519F, 63.3355103F, 81.9422913F,
    10.7875252F, 68.122673F, 6.64248466F, 73.9153061F, 99.7872086F, 66.3288345F,
    98.977478F, 75.4347839F, 29.4896793F, 78.0674286F, 44.4530907F, 4.45854378F,
    53.8393631F, 95.2222F, 12.1444082F, 64.1698837F, 22.3126774F, 37.8784294F,
    46.2867966F, 43.0607071F, 89.3816376F, 51.1320534F, 49.6027336F, 39.8025665F,
    80.1298294F, 78.917511F, 80.9695358F, 64.7146072F, 47.4817619F, 29.5790501F,
    27.352684F, 91.9777679F, 0.799249232F, 52.491539F, 46.6815834F, 25.9005623F,
    9.58513F, 38.0416565F, 73.6744919F, 32.7804794F, 44.1793213F, 9.30968285F,
    3.86650491F, 47.7676468F, 43.1904907F, 96.4071045F, 42.5430412F, 92.0011139F,
    67.1340408F, 44.8919373F, 39.3712883F, 89.1477432F, 58.2106361F, 59.519825F,
    85.5440521F, 31.8564568F, 35.1956825F, 73.5877304F, 37.455204F, 14.4684515F,
    0.684090853F, 40.8486938F, 50.9774933F, 87.3061676F, 86.0660172F,
    35.5402641F, 20.2757053F, 79.3363724F, 80.2825546F, 92.2367706F, 24.4498348F,
    21.652771F, 63.2817688F, 22.1471F, 56.2633209F, 8.90999317F, 62.6475525F,
    78.348732F, 48.5889282F, 27.8255672F, 32.0490189F, 48.4648361F, 13.8098555F,
    35.7178802F, 26.6418724F, 90.2460175F, 80.6907578F, 66.1242676F, 97.2704468F,
    42.8762F, 53.1640472F, 91.8247299F, 8.0629158F, 21.0051632F, 40.0734634F,
    66.9615402F, 55.3614655F, 13.6837368F, 12.9904585F, 76.1859665F, 2.24066329F,
    85.9877319F, 19.3692188F, 18.1614437F, 52.0099831F, 98.1734695F, 40.1515198F,
    93.4436417F, 35.3786583F, 43.120842F, 62.0767593F, 60.5286713F, 9.18101215F,
    11.3460369F, 20.0183506F, 76.1165466F, 5.16544151F, 84.6077881F, 15.1345339F,
    98.8674316F, 66.3273392F, 24.7135639F, 54.5426025F, 19.0119648F, 32.8988457F,
    28.6355743F, 58.2241325F, 91.862915F, 13.5130692F, 50.3245926F, 88.2774811F,
    72.9495697F, 52.0280495F, 40.4235458F, 88.8701782F, 38.7522469F, 22.5285263F,
    87.2455292F, 88.3317337F, 5.58507252F, 70.0407181F, 80.2295303F, 8.35707855F,
    2.37360191F, 31.1853943F, 42.8015137F, 30.1652985F, 90.8951263F, 39.0801315F,
    39.4391556F, 35.0435867F, 81.6015091F, 51.4315834F, 84.7840347F, 86.148735F,
    92.0024414F, 87.3636856F, 55.8200302F, 56.4867821F, 53.9347191F, 14.0466375F,
    78.1421661F, 8.57462F, 83.5756073F, 15.0678186F, 57.549324F, 63.6060181F,
    78.9723816F, 47.6722717F, 84.8613205F, 89.8924103F, 34.3045158F, 62.028038F,
    8.56343174F, 19.6459599F, 68.0373077F, 39.3510857F, 37.4599419F, 7.51798153F,
    70.7142F, 4.43527031F, 83.3723602F, 59.0479774F, 92.9150925F, 41.8873672F,
    69.565712F, 63.5337715F, 85.204689F, 19.4743557F, 24.6234264F, 91.6975937F,
    51.8829765F, 45.4020462F, 15.5013714F, 85.3464508F, 31.8761673F, 50.1300964F,
    91.800209F, 44.1734734F, 11.1329784F, 90.208931F, 88.6745911F, 61.0286636F,
    31.5645714F, 43.8080215F, 51.2506142F, 42.3173714F, 44.6850815F, 72.3191071F,
    90.9656372F, 82.4966583F, 80.8511353F, 61.0651398F, 96.8662109F, 63.2374611F,
    97.8334198F, 82.3952866F, 67.6260834F, 47.8226357F, 7.871943F, 91.8379745F,
    85.515213F, 55.6387482F, 86.7610474F, 67.2713165F, 19.5764809F, 29.3325138F,
    74.9741364F, 47.6485252F, 37.369F, 93.1877136F, 43.3586044F, 7.44348526F,
    51.7554131F, 59.8549347F, 58.5024376F, 50.776535F, 90.6041565F, 98.0163879F,
    74.6740417F, 75.5304565F, 53.8190575F, 39.4703712F, 61.4867401F, 43.023571F,
    44.9845314F, 49.1546059F, 14.0691595F, 82.3466339F, 25.225275F, 85.8019943F,
    59.8460922F, 94.6981125F, 69.1233521F, 3.1331327F, 38.8352165F, 18.1759319F,
    48.1686974F, 69.5080109F, 3.28802347F, 3.32304764F, 44.8727608F, 35.9181137F,
    63.2799454F };

  RT_LOCAL_DATA static const float fv1[16] = { 370.610291F, 370.602905F, 1.07521522F,
    1.07519376F, 364.486938F, 364.479675F, 0.923601866F, 0.923583388F,
    366.016205F, 366.008881F, 0.718159676F, 0.71814537F, 379.377441F,
    379.369873F, 0.64530623F, 0.645293355F };


/////////////////////////////////////////////////////////
// subfunctions
/////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////
// main testing function 
/////////////////////////////////////////////////////////
int main(int argc, const char * const argv[])
{
  if (rt_cluster_id() != 0)
    return bench_cluster_forward(0);

  (void)argc;
  (void)argv;

  int coreid;
  int it;

  int k;
  boolean_T pass, flag;
  float y[100];
  int ix;
  float b_y;
  float xbar;
  float r;
  float c_y;
  float tmp[2];
  float golden[4];


  /////////////////////////////////////////////////////////
  // main test loop 
  // each core loops over a kernel instance
  /////////////////////////////////////////////////////////

  coreid = rt_core_id();

  printf("starting %d kernel iterations... (coreid = %d)\n",KERNEL_ITS,coreid);

    if (coreid>3)
    coreid= (coreid-4) % 4;

  synch_barrier();

  perf_begin();

  for(it = 0; it < KERNEL_ITS; it++)
  {
    // matlab kernel
    for (ix = 0; ix < 100; ix++) {
      y[ix] = (real32_T)fLog(fv0[ix + 100 * coreid]);
    }
  }

  synch_barrier();

  perf_end();

  synch_barrier();

  /////////////////////////////////////////////////////////
  // check results
  /////////////////////////////////////////////////////////

  pass = true;
  b_y = y[0];
  ix = 0;
  xbar = y[0];
  for (k = 0; k < 99; k++) {
    b_y += y[k + 1];
    ix++;
    xbar += y[ix];
  }

  xbar *= 1.0F/100.0F;
  ix = 0;
  r = y[0] - xbar;
  c_y = r * r;
  for (k = 0; k < 99; k++) {
    ix++;
    r = y[ix] - xbar;
    c_y += r * r;
  }

  c_y *= 1.0F/99.0F;
  tmp[0] = b_y;
  tmp[1] = c_y;
  pass  = true;

  for (ix = 0; ix < 2; ix++) {
    for (k = 0; k < 2; k++) {
      golden[k + (ix << 1)] = fv1[(k + (ix << 1)) + (coreid << 2)];
    }
    flag = true;
    flag = flag && (tmp[ix] <= golden[ix << 1]);
    flag = flag && (tmp[ix] >= golden[1 + (ix << 1)]);
    printErrors(!flag, ix, tmp[ix] ,golden[(ix << 1)] ,golden[1 + (ix << 1)]);
    pass = pass && flag;
  }

  flagPassFail(pass, get_core_id());
  
  synch_barrier();

/////////////////////////////////////////////////////////
// synchronize and exit
/////////////////////////////////////////////////////////

  return !pass;
}

