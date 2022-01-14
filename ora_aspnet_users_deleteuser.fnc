CREATE OR REPLACE FUNCTION IPTV."ORA_ASPNET_USERS_DELETEUSER" wrapped
0
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
3
8
9200000
1
4
0
3b
2 :e:
1FUNCTION:
1ORA_ASPNET_USERS_DELETEUSER:
1APPLICATIONNAME_:
1NVARCHAR2:
1USERNAME_:
1TABLESTODELETEFROM:
1INTEGER:
1NUMTABLESDELETEDFROM:
1OUT:
1RETURN:
1TABLE_DOES_NOT_EXIST:
1PRAGMA:
1EXCEPTION_INIT:
1-:
10942:
1M_USERID:
1RAW:
116:
1M_NUMTABLESDELETEDFROM:
10:
1M_CURSOR:
1NUMBER:
1M_DELETESTRING:
1256:
1M_ROWSDELETED:
1U:
1USERID:
1ORA_ASPNET_APPLICATIONS:
1A:
1ORA_ASPNET_USERS:
1LOWEREDAPPLICATIONNAME:
1LOWER:
1=:
1APPLICATIONID:
1LOWEREDUSERNAME:
1NO_DATA_FOUND:
1DBMS_SQL:
1OPEN_CURSOR:
1BITAND:
11:
1!=:
1DELETE FROM ora_aspnet_Membership WHERE UserId = ::x:
1PARSE:
1NATIVE:
1BIND_VARIABLE:
1::x:
1EXECUTE:
1>:
1+:
12:
1DELETE FROM ora_aspnet_UsersInRoles WHERE UserId = ::x:
14:
1DELETE FROM ora_aspnet_Profile WHERE UserId = ::x:
18:
1DELETE FROM ora_aspnet_PersonaliznPerUser WHERE UserId = ::x:
1DELETE FROM ora_aspnet_Users WHERE UserId = ::x:
1CLOSE_CURSOR:
1OTHERS:
1RAISE:
0

0
0
219
2
0 a0 8d 8f a0 b0 3d 8f
a0 b0 3d 8f a0 b0 3d 90
:2 a0 b0 3f b4 :2 a0 2c 6a 8b
b0 2a :3 a0 7e 51 b4 2e b4
5d a3 a0 51 a5 1c 4d 81
b0 a3 a0 1c 51 81 b0 a3
a0 1c 51 81 b0 a3 a0 51
a5 1c 4d 81 b0 a3 a0 1c
51 81 b0 :2 a0 6b ac :3 a0 b9
:2 a0 b9 b2 ee :2 a0 6b a0 7e
a0 a5 b b4 2e :2 a0 6b a0
7e a0 6b b4 2e a 10 :2 a0
6b a0 7e a0 a5 b b4 2e
a 10 ac e5 d0 b2 e9 b7
:2 a0 51 65 b7 a6 9 a4 b1
11 4f :3 a0 6b d :2 a0 51 a5
b 7e 51 b4 2e a0 6e d
:2 a0 6b :4 a0 6b a5 57 :2 a0 6b
a0 6e a0 a5 57 :3 a0 6b a0
a5 b d b7 a0 4f b7 a6
9 a4 b1 11 4f a0 7e 51
b4 2e :2 a0 7e 51 b4 2e d
b7 19 3c b7 19 3c :2 a0 51
a5 b 7e 51 b4 2e a0 6e
d :2 a0 6b :4 a0 6b a5 57 :2 a0
6b a0 6e a0 a5 57 :3 a0 6b
a0 a5 b d b7 a0 4f b7
a6 9 a4 b1 11 4f a0 7e
51 b4 2e :2 a0 7e 51 b4 2e
d b7 19 3c b7 19 3c :2 a0
51 a5 b 7e 51 b4 2e a0
6e d :2 a0 6b :4 a0 6b a5 57
:2 a0 6b a0 6e a0 a5 57 :3 a0
6b a0 a5 b d b7 a0 4f
b7 a6 9 a4 b1 11 4f a0
7e 51 b4 2e :2 a0 7e 51 b4
2e d b7 19 3c b7 19 3c
:2 a0 51 a5 b 7e 51 b4 2e
a0 6e d :2 a0 6b :4 a0 6b a5
57 :2 a0 6b a0 6e a0 a5 57
:3 a0 6b a0 a5 b d b7 a0
4f b7 a6 9 a4 b1 11 4f
a0 7e 51 b4 2e :2 a0 7e 51
b4 2e d b7 19 3c b7 19
3c :2 a0 51 a5 b 7e 51 b4
2e :2 a0 51 a5 b 7e 51 b4
2e a 10 :2 a0 51 a5 b 7e
51 b4 2e a 10 :2 a0 51 a5
b 7e 51 b4 2e a 10 a0
6e d :2 a0 6b :4 a0 6b a5 57
:2 a0 6b a0 6e a0 a5 57 :3 a0
6b a0 a5 b d b7 a0 4f
b7 a6 9 a4 b1 11 4f a0
7e 51 b4 2e :2 a0 7e 51 b4
2e d b7 19 3c b7 19 3c
:2 a0 d :2 a0 6b a0 a5 57 a0
51 65 b7 a0 53 :2 a0 6b a0
a5 57 a0 62 b7 a6 9 a4
a0 b1 11 68 4f 1d 17 b5
219
2
0 3 7 23 1f 1e 2b 38
34 1b 40 49 45 33 51 62
5a 5e 30 69 59 6e 72 76
7a 7e 56 85 88 8c 90 94
97 9a 9b a0 a1 be a8 ac
af b0 b8 b9 a7 da c9 cd
a4 d5 c8 f6 e5 e9 c5 f1
e4 114 101 e1 105 106 10e 10f
100 130 11f 123 fd 12b 11e 137
13b 11b 13f 140 144 148 14c 14e
152 156 158 159 160 164 168 16b
16f 172 176 177 179 17a 17f 183
187 18a 18e 191 195 198 199 1
19e 1a3 1a7 1ab 1ae 1b2 1b5 1b9
1ba 1bc 1bd 1 1c2 1c7 1c8 1ce
1d2 1d3 1d8 1da 1de 1e2 1e5 1e9
1eb 1ec 1f1 1f5 1f7 203 205 209
20d 211 214 218 21c 220 223 224
226 229 22c 22d 232 236 23b 23f
243 247 24a 24e 252 256 25a 25d
25e 263 267 26b 26e 272 277 27b
27c 281 285 289 28d 290 294 295
297 29b 29d 2a1 2a3 2a5 2a6 2ab
2af 2b1 2bd 2bf 2c3 2c6 2c9 2ca
2cf 2d3 2d7 2da 2dd 2de 2e3 2e7
2e9 2ed 2f0 2f2 2f6 2f9 2fd 301
304 305 307 30a 30d 30e 313 317
31c 320 324 328 32b 32f 333 337
33b 33e 33f 344 348 34c 34f 353
358 35c 35d 362 366 36a 36e 371
375 376 378 37c 37e 382 384 386
387 38c 390 392 39e 3a0 3a4 3a7
3aa 3ab 3b0 3b4 3b8 3bb 3be 3bf
3c4 3c8 3ca 3ce 3d1 3d3 3d7 3da
3de 3e2 3e5 3e6 3e8 3eb 3ee 3ef
3f4 3f8 3fd 401 405 409 40c 410
414 418 41c 41f 420 425 429 42d
430 434 439 43d 43e 443 447 44b
44f 452 456 457 459 45d 45f 463
465 467 468 46d 471 473 47f 481
485 488 48b 48c 491 495 499 49c
49f 4a0 4a5 4a9 4ab 4af 4b2 4b4
4b8 4bb 4bf 4c3 4c6 4c7 4c9 4cc
4cf 4d0 4d5 4d9 4de 4e2 4e6 4ea
4ed 4f1 4f5 4f9 4fd 500 501 506
50a 50e 511 515 51a 51e 51f 524
528 52c 530
/

