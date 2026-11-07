# Game table columns

Column names of every table in the client's tables.bin, read from the game code (`Struct_<Table>::InitMemberNames` in libgame.so).
Index = position in `server/data/<table>.json` rows (index 0 is the row key, index N = name N). Made by `tools/table_columns.py`.
"NOT read by the server" = no server or tool code names the table. normalconfig is one value per row: see its rows (Chinese descriptions) in the json.

## chestbox (0 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 0 |  |
| 2 | m_checkicon | 0 |  |
| 3 | m_addpower | 0 |  |
| 4 | m_addpowerrate | 0 |  |
| 5 | m_addgold | 0 |  |
| 6 | m_addgoldrate | 0 |  |
| 7 | m_addsilver | 0 |  |
| 8 | m_addsilverrate | 0 |  |
| 9 | m_ninjaid | 0 |  |
| 10 | m_ninjarate | 0 |  |
| 11 | m_equipid | 0 |  |
| 12 | m_equiprate | 0 |  |
| 13 | m_regetblood | 0 |  |
| 14 | m_regetbloodrate | 0 |  |

## consumeinfo (41 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 41 | 1, 2, 3, 4, 5, 6 |
| 2 | m_namestr | 41 | Tael (small), Tael (large), Rāmen Ichiraku (Small), Rāmen Ichiraku (Large), Hyourou-gan (Small), Hyourou-gan (Big) |
| 3 | m_icon | 41 | props_020, props_021, props_016, props_017, props_011, props_012 |
| 4 | m_needgold | 13 | 5, 25, 10, 20, 8, 0 |
| 5 | m_needsilver | 1 | 0 |
| 6 | m_consumedesc | 41 | You will get 2000 silver after use, You will get 10000 silver after use, 100 energy points will be recovered afte, 200 energy points will be recovered afte, Recover 50% Duel Points after use, Recover 100% Duel Points after use |
| 7 | m_consumetype | 20 | 3, 1, 2, 7, 4, 5 |
| 8 | m_para1 | 16 | 2000.0, 10000.0, 100.0, 200.0, 0.5, 1.0 |
| 9 | m_para2 | 14 | 0.0, 10.0, 11.0, 12.0, 13.0, 15.0 |
| 10 | m_para3 | 4 | 0.0, 2015.0, 2017.0, 6.0 |
| 11 | m_para4 | 2 | 0.0, 1.0 |
| 12 | m_para5 | 1 | 0.0 |

## countrywarhonor (8 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 8 | 1, 2, 3, 4, 5, 6 |
| 2 | m_warhonor | 8 | War Shinobi Dragon, War Shinobi Sage, War Kage, War Special Forces Shinobi, War Jōnin, War Chunin |
| 3 | m_needfeats | 8 | 1800000, 720000, 360000, 180000, 36000, 18000 |

## dailytask_info (24 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 24 | 1, 2, 3, 4, 5, 6 |
| 2 | m_dailytask_name | 24 | Complete training 20 times, Clear Level 5 times, synthesize 2 Seals, Arena Challenge 5 times, Shinobi Growth 5 Times, Win Spar 5 times |
| 3 | m_dailytask_title | 23 | Training, Advance, Plunder, Arena, Growth, Spar |
| 4 | m_dailytask_type | 24 | 1, 2, 3, 4, 5, 6 |
| 5 | m_dailytask_value1 | 6 | 20, 5, 2, 3, 1, 1000 |
| 6 | m_dailytask_points | 5 | 10, 15, 5, 40, 30 |
| 7 | m_dailytask_onoff | 2 | 1, 0 |

## dropinfo (2149 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 2149 | 1, 2, 3, 4, 5, 6 |
| 2 | m_dropdesc | 1393 | Higher chance to gain Five-Star Purple C, Possibility of Five-Star Card, higher ch, Possibility to win Five-Star Card, certa, 10 Upgrade Shinobi Card (Chōji Akimichi), 50 Upgrade Shinobi Card (Chōji Akimichi), 10 Armor Material Card (Samurai Attire) |
| 3 | m_ninja_id | 370 | 262, 298, 100015, 0, 2014, 194 |
| 4 | m_equip_id | 61 | 0, 71, 59, 56, 70, 61 |
| 5 | m_skill_id | 40 | 0, 53, 52, 37, 54, 27 |
| 6 | m_mark_id | 9 | 0, 91, 90, 10, 9, 5 |
| 7 | m_prop_id | 38 | 0, 4, 13, 11, 12, 7 |
| 8 | m_suipians_id | 173 | 0, 1, 6, 7, 8, 9 |
| 9 | m_renhuns_num | 17 | 0, 2000, 1000, 200, 700, 800 |
| 10 | m_yuanbao_num | 52 | 0, 10, 20, 30, 40, 50 |
| 11 | m_yinzi_num | 44 | 0, 1500, 2000, 2500, 3000, 3500 |
| 12 | m_drop_type | 2 | 1, 2 |
| 13 | m_drop_num | 41 | 1, 10, 50, 2, 3, 4 |
| 14 | m_pet_id | 9 | 0, 1, 2, 3, 4, 5 |

## duelinfo (597 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 597 | 1, 2, 3, 4, 5, 6 |
| 2 | m_enemylevel | 350 | 1, 2, 3, 4, 5, 6 |
| 3 | m_win_silver | 8 | 0.01, 0.02, 0.03, 0.04, 0.05, 0.06 |
| 4 | m_fail_silver | 8 | 0.01, 0.02, 0.03, 0.04, 0.05, 0.06 |
| 5 | m_win_exp | 273 | 1, 2, 3, 4, 5, 6 |
| 6 | m_fail_exp | 102 | 1, 2, 3, 4, 5, 6 |
| 7 | m_win_madel | 1 | 15 |
| 8 | m_fail_medel | 1 | 5 |
| 9 | m_consumeval | 1 | 1 |
| 10 | m_equipid | 1 | 27 |

## equipbookrank (81 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 81 | 1, 2, 3, 4, 5, 6 |
| 2 | m_icon | 81 | weapon_042, weapon_040, weapon_038, weapon_036, weapon_033, weapon_039 |
| 3 | m_equipid | 81 | 84, 83, 81, 79, 74, 82 |

## equipmentinfo (84 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 84 | 1, 2, 3, 4, 5, 6 |
| 2 | m_equipname | 84 | Bashōsen, Sword of Totsuka, Sword of Kusanagi, Adamantine Staff, Sword of Flying Thunder God, Greatsword.Samehada |
| 3 | m_equiptype | 3 | 0, 1, 2 |
| 4 | m_equipicon | 81 | weapon_002, weapon_031, weapon_030, weapon_029, weapon_028, weapon_027 |
| 5 | m_e_level | 2 | 1, 3 |
| 6 | m_quality | 5 | 5, 4, 3, 2, 1 |
| 7 | m_attackmin | 40 | 200, 175, 150, 135, 121, 120 |
| 8 | m_attackmax | 40 | 200, 175, 150, 135, 121, 120 |
| 9 | m_defensemin | 27 | 0, 200, 175, 150, 140, 121 |
| 10 | m_defensemax | 27 | 0, 200, 175, 150, 140, 121 |
| 11 | m_chakrasmin | 20 | 0, 200, 165, 150, 130, 100 |
| 12 | m_chakrasmax | 20 | 0, 200, 165, 150, 130, 100 |
| 13 | m_attackmin_up | 20 | 13, 12, 11, 10, 9, 8 |
| 14 | m_attackmax_up | 20 | 13, 12, 11, 10, 9, 8 |
| 15 | m_defensemin_up | 15 | 0, 13, 12, 11, 10, 9 |
| 16 | m_defensemax_up | 15 | 0, 13, 12, 11, 10, 9 |
| 17 | m_chakrasmin_up | 14 | 0, 13, 12, 11, 10, 9 |
| 18 | m_chakrasmax_up | 14 | 0, 13, 12, 11, 10, 9 |
| 19 | m_equipdesc | 84 | It can launch attacks of any attribute. , Sword of Totsuka. Equip it to [Itachi Uc, Orochimaru killed Sandaime with this wea, Sandaime's spirit beast Enma can become , It bears great Thunder power, stolen by , It's a conscious blade. Equip it to [Kis |
| 20 | m_sellprice | 1 | 50 |
| 21 | m_equip_skill | 8 | 8, 0, 10, 11, 13, 12 |

## equipnewlifeprop (3 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 3 | 1, 2, 3 |
| 2 | m_newlife_equip_pinzhi | 1 | 5 |
| 3 | m_newlife_times | 3 | 1, 2, 3 |
| 4 | m_newlife_times_basis | 3 | 0.5, 1.5, 3.5 |
| 5 | m_newlife_times_grow | 3 | 0.5, 1.5, 3.5 |

## equipupgrade (50 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 50 | 1, 2, 3, 4, 5, 6 |
| 2 | m_needexp | 49 | 50, 100, 150, 200, 250, 300 |
| 3 | m_costexp | 50 | 250, 300, 450, 500, 562, 787 |
| 4 | m_needsilver | 50 | 150, 180, 270, 300, 337, 472 |
| 5 | m_sellprice | 50 | 50, 100, 150, 200, 250, 300 |

## exchange_award (12 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 12 | 1, 2, 3, 4, 5, 6 |
| 2 | m_tianti_exchange_name | 12 | The first, The second, The third , The four , The five , The six  |
| 3 | m_tianti_exchange_num | 6 | 1, 2, 5, 30, 15, 10 |
| 4 | m_tianti_exchange_totaltimes | 2 | 1, 0 |
| 5 | m_tianti_exchange_todaytimes | 3 | 0, 2, 4 |
| 6 | m_tianti_exchange_need | 6 | 480000, 15000, 8000, 40000, 80000, 120000 |
| 7 | m_tianti_exchange_drop | 12 | 352, 1527, 1515, 1668, 1309, 1310 |
| 8 | m_tianti_exchange_show | 12 | 475, 474, 476, 477, 254, 255 |
| 9 | m_tianti_exchange_description | 12 | Sasuke Uchiha(Attack Card), Development Dan, Double Exp Pill, Element Change Pil, Seal of Kyubi, Seal of Ten Tails |

## fillDropData (477 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 477 | 1, 2, 3, 4, 5, 6 |
| 2 | m_drop_value_name | 279 | Kidomaru, Sakon Ukon, Gekkou Hayate, Tayuya, Jiroubou, Kiba Inuzuka |
| 3 | m_drop_value_icon | 251 | npc17_3, npc17_2, npc05_3, npc19_2, npc17_5, npc06_6 |
| 4 | m_drop_value_star | 6 | 2, 1, 3, 0, 4, 5 |
| 5 | m_drop_value_type1 | 5 | 1, 2, 3, 4, 6 |
| 6 | m_drop_value_type2 | 38 | 1, 2, 4, 6, 24, 23 |
| 7 | m_drop_value_id | 201 | 96, 97, 98, 99, 100, 101 |
| 8 | m_drop_value_type3 | 5 | 1, 2, 4, 5, 6 |

## firstpurchase (1 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 1 | 1 |
| 2 | m_dropid1 | 1 | 1498 |
| 3 | m_dropicon1 | 1 | npc02_1 |
| 4 | m_dropdesc1 | 1 | Senju Tsunade (God) |
| 5 | m_dropid2 | 1 | 356 |
| 6 | m_dropicon2 | 1 | weapon_030 |
| 7 | m_dropdesc2 | 1 | Sword of Kusanagi |
| 8 | m_dropid3 | 1 | 1114 |
| 9 | m_dropicon3 | 1 | skill_043 |
| 10 | m_dropdesc3 | 1 | Big Ball Rasengan |

## functionconfig (22 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 22 | 1, 2, 3, 4, 5, 6 |
| 2 | m_funcname | 22 | Advance, Plunder, Training, War, Competition, National treasure |
| 3 | m_needlevel | 9 | 30, 10, 0, 25, 45, 40 |
| 4 | m_tipinfo | 14 | Advancement level 30 unlocked, please wo, Plunder level 10 unlocked, please work h, , Competition level 25 unlocked, please wo, National Treasure level 45 unlocked, ple, Money Tree level 40 unlocked, please wor |

## giftinfo (22 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 22 | 1, 2, 3, 4, 5, 6 |
| 2 | m_giftname | 22 | Ninja Bag (S), Ninja Bag (L), Weapon Bag (S), Armor Bag (S), Trinket Bag (S), Skill Bag (S) |
| 3 | m_icon | 19 | props_009, props_010, props_005, props_001, props_029, props_043 |
| 4 | m_price_gold | 12 | 0, 280, 80, 300, 100, 150 |
| 5 | m_price_silver | 3 | 2800, 13000, 0 |
| 6 | m_giftdesc | 22 | Contains 10 ninja cards that can upgrade, Contains 50 ninja cards that can upgrade, Contains 10 weapon cards that can upgrad, Contains 10 armor cards that can upgrade, Contains 10 trinket cards that can upgra, Contains 10 skill cards that can upgrade |
| 7 | m_gifttype | 2 | 1, 2 |
| 8 | m_para1 | 19 | 4.0, 5.0, 224.0, 6.0, 223.0, 8.0 |
| 9 | m_para2 | 5 | 0.0, 1.0, 10.0, 50.0, 100.0 |
| 10 | m_para3 | 1 | 0.0 |
| 11 | m_para4 | 1 | 0.0 |

## iapiteminfo (10 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 10 | 1, 2, 3, 4, 5, 6 |
| 2 | m_needmoney | 8 | 150000.0, 100000.0, 50000.0, 30000.0, 10000.0, 5000.0 |
| 3 | m_goldnum | 8 | 15000, 10000, 5000, 3000, 1000, 500 |
| 4 | m_freegoldnum | 10 | 9000, 6000, 2500, 1500, 500, 200 |
| 5 | m_itemdesc | 1 |  |

## ladderconfig (2000 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 2000 | 1, 2, 3, 4, 5, 6 |
| 2 | m_rewardid | 8 | 159, 160, 161, 162, 163, 164 |

## ladderdesc (7 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 7 | 1, 2, 3, 4, 5, 6 |
| 2 | m_startnum | 7 | 1, 2, 6, 21, 51, 201 |
| 3 | m_endnum | 7 | 1, 5, 20, 50, 200, 500 |
| 4 | m_dropid | 7 | 159, 160, 161, 162, 163, 164 |
| 5 | m_dropdesc | 7 | You will get one of these 4 rewards: Fiv, You will get one of these 4 rewards: Fiv, You will get one of these 4 rewards: Fiv, You will get one of these 3 rewards: Fou, You will get one of these 3 rewards: Fou, You will get one of these 3 rewards: Fou |

## markinfo (91 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 91 | 1, 2, 3, 4, 5, 6 |
| 2 | m_markname | 91 | Shukaku Seal, Matatabi Seal, Isobu Seal, Son Gokū Seal, Kokuō Seal, Saiken Seal |
| 3 | m_marktype | 2 | 0, 1 |
| 4 | m_markicon | 90 | hallmark_1, hallmark_2, hallmark_3, hallmark_4, hallmark_5, hallmark_6 |
| 5 | m_marklevel | 1 | 1 |
| 6 | m_quality | 4 | 3, 4, 5, 1 |
| 7 | m_markdesc | 83 | ATK +35% , ATK +40% , DEF +45%, DEF +50% , DEF and ATK +30%, DEF and ATK +40% |
| 8 | m_sellprice | 1 | 50 |
| 9 | effectval1_1 | 6 | 0.07, 0.05, 0.0, 0.06, 0.04, 0.16 |
| 10 | effectval1_2 | 7 | 0.0, 0.07, 0.08, 0.06, 0.05, 0.04 |
| 11 | effectval1_3 | 2 | 0.0, 0.12 |
| 12 | effectval1_4 | 5 | 0.0, 0.002, 0.004, 0.006, 0.016 |
| 13 | effectval2_1 | 6 | 0.05, 0.08, 0.0, 0.04, 0.06, 0.12 |
| 14 | effectval2_2 | 5 | 0.0, 0.06, 0.04, 0.08, 0.09 |
| 15 | effectval2_3 | 2 | 0.0, 0.08 |
| 16 | effectval2_4 | 4 | 0.0, 0.004, 0.006, 0.01 |
| 17 | effectval3_1 | 6 | 0.04, 0.06, 0.0, 0.08, 0.14, 0.07 |
| 18 | effectval3_2 | 8 | 0.0, 0.09, 0.05, 0.06, 0.04, 0.08 |
| 19 | effectval3_3 | 2 | 0.0, 0.07 |
| 20 | effectval3_4 | 4 | 0.0, 0.006, 0.004, 0.008 |
| 21 | effectval4_1 | 6 | 0.03, 0.0, 0.05, 0.08, 0.09, 0.12 |
| 22 | effectval4_2 | 7 | 0.0, 0.04, 0.07, 0.05, 0.08, 0.12 |
| 23 | effectval4_3 | 2 | 0.0, 0.12 |
| 24 | effectval4_4 | 4 | 0.0, 0.004, 0.006, 0.016 |
| 25 | effectval5_1 | 7 | 0.02, 0.04, 0.0, 0.03, 0.05, 0.1 |
| 26 | effectval5_2 | 6 | 0.0, 0.05, 0.1, 0.03, 0.14, 0.06 |
| 27 | effectval5_3 | 2 | 0.0, 0.06 |
| 28 | effectval5_4 | 4 | 0.0, 0.006, 0.002, 0.008 |
| 29 | effectval_up1_1 | 6 | 0.0057, 0.0041, 0.0, 0.0049, 0.0033, 0.0131 |
| 30 | effectval_up1_1 | 7 | 0.0, 0.0057, 0.0065, 0.0049, 0.0041, 0.0033 |
| 31 | effectval_up1_1 | 2 | 0.0, 0.0098 |
| 32 | effectval_up1_1 | 5 | 0.0, 0.0002, 0.0003, 0.0005, 0.0013 |
| 33 | effectval_up2_1 | 6 | 0.0041, 0.0065, 0.0, 0.0033, 0.0049, 0.0098 |
| 34 | effectval_up2_1 | 5 | 0.0, 0.0049, 0.0033, 0.0065, 0.0073 |
| 35 | effectval_up2_1 | 2 | 0.0, 0.0065 |
| 36 | effectval_up2_1 | 4 | 0.0, 0.0003, 0.0005, 0.0008 |
| 37 | effectval_up3_1 | 6 | 0.0033, 0.0049, 0.0, 0.0082, 0.0114, 0.0057 |
| 38 | effectval_up3_1 | 7 | 0.0, 0.0073, 0.0041, 0.0049, 0.0033, 0.0082 |
| 39 | effectval_up3_1 | 2 | 0.0, 0.0057 |
| 40 | effectval_up3_1 | 4 | 0.0, 0.0005, 0.0003, 0.0007 |
| 41 | effectval_up4_1 | 6 | 0.0024, 0.0, 0.0041, 0.0065, 0.0073, 0.0098 |
| 42 | effectval_up4_1 | 7 | 0.0, 0.0033, 0.0057, 0.0041, 0.0065, 0.0098 |
| 43 | effectval_up4_1 | 2 | 0.0, 0.0098 |
| 44 | effectval_up4_1 | 4 | 0.0, 0.0003, 0.0005, 0.0013 |
| 45 | effectval_up5_1 | 8 | 0.0016, 0.0033, 0.0, 0.0024, 0.0041, 0.0065 |
| 46 | effectval_up5_1 | 7 | 0.0, 0.0041, 0.0082, 0.0024, 0.0065, 0.0114 |
| 47 | effectval_up5_1 | 2 | 0.0, 0.0049 |
| 48 | effectval_up5_1 | 4 | 0.0, 0.0005, 0.0002, 0.0007 |
| 49 | m_mark_suit | 8 | 0, 13, 12, 11, 10, 9 |

## markmerge (10 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 10 | 1, 2, 3, 4, 5, 6 |
| 2 | m_markingname | 10 | Shukaku Seal, Matatabi Seal, Isobu Seal, Son Gokū Seal, Kokuō Seal, Saiken Seal |
| 3 | m_markingtile1 | 10 | 11, 19, 27, 35, 43, 51 |
| 4 | m_markingtile2 | 10 | 12, 20, 28, 36, 44, 52 |
| 5 | m_markingtile3 | 10 | 13, 21, 29, 37, 45, 53 |
| 6 | m_markingtile4 | 10 | 14, 22, 30, 38, 46, 54 |
| 7 | m_markingtile5 | 10 | 15, 23, 31, 39, 47, 55 |
| 8 | m_markingtile6 | 7 | 16, 24, 0, 64, 72, 80 |
| 9 | m_markingtile7 | 3 | 0, 73, 89 |
| 10 | m_markingtile8 | 3 | 0, 74, 90 |
| 11 | m_markingtilename1 | 10 | Shukaku Seal Fragment 1, Matatabi Seal Fragment 1, Isobu Seal Fragment 1, Son Gokū Seal Fragment 1, Kokuō Seal Fragment 1, Saiken Seal Fragment 1 |
| 12 | m_markingtilename2 | 10 | Shukaku Seal Fragment 2, Matatabi Seal Fragment 2, Isobu Seal Fragment 2, Son Gokū Seal Fragment 2, Kokuō Seal Fragment 2, Saiken Seal Fragment 2 |
| 13 | m_markingtilename3 | 10 | Shukaku Seal Fragment 3, Matatabi Seal Fragment 3, Isobu Seal Fragment 3, Son Gokū Seal Fragment 3, Kokuō Seal Fragment 3, Saiken Seal Fragment 3 |
| 14 | m_markingtilename4 | 10 | Shukaku Seal Fragment 4, Matatabi Seal Fragment 4, Isobu Seal Fragment 4, Son Gokū Seal Fragment 4, Kokuō Seal Fragment 4, Saiken Seal Fragment 4 |
| 15 | m_markingtilename5 | 10 | Shukaku Seal Fragment 5, Matatabi Seal Fragment 5, Isobu Seal Fragment 5, Son Gokū Seal Fragment 5, Kokuō Seal Fragment 5, Saiken Seal Fragment 5 |
| 16 | m_markingtilename6 | 7 | Shukaku Seal Fragment 6, Matatabi Seal Fragment 6, , Chōmei Seal Fragment 6, Gyūki Seal Fragment 6, Kurama Seal Fragment 6 |
| 17 | m_markingtilename7 | 3 | , Gyūki Seal Fragment 7, Ten Tails Seal Fragment 7 |
| 18 | m_markingtilename8 | 3 | , Gyūki Seal Fragment 8, Ten Tails Seal Fragment 8 |

## markupgrade (50 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 50 | 1, 2, 3, 4, 5, 6 |
| 2 | m_needexp | 50 | 50, 100, 150, 200, 250, 300 |
| 3 | m_costexp | 50 | 50, 75, 150, 250, 375, 525 |
| 4 | m_needsilver | 50 | 100, 150, 300, 500, 750, 1050 |
| 5 | m_sellprice | 50 | 50, 100, 150, 200, 250, 300 |

## newcardinfo (26 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 26 | 1, 2, 3, 4, 5, 6 |
| 2 | m_param1 | 26 | 1.   you to reach level 1, 1.   you to reach level 2, 1.   you to reach level 6, 1.   you to reach level 15, 1.   Lv. 30 and customs clearance 1 Roun, 1.   Lv. 50 and customs clearance 2 Roun |
| 3 | m_param2 | 9 | , 2.  Middle Chūnin, and  level is above 2, 2.  Senior Chūnin, and  level is above 2, 2.  Elite Chūnin, and  level is above 24, 2.  Junior Jōnin, and  level is above 25, 2.  Middle Jōnin, and  level is above 26 |
| 4 | m_param3 | 1 |  |
| 5 | m_param4 | 1 |  |
| 6 | m_param5 | 1 |  |
| 7 | m_exp_limit1 | 9 | 0, 1, 2, 4, 7, 9 |
| 8 | m_exp_limit2 | 8 | 0, 12, 10, 4, 6, 1 |

## newlifeconfig (54 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 54 | 1, 2, 3, 4, 5, 6 |
| 2 | m_newlife_count | 9 | 1, 2, 3, 4, 5, 6 |
| 3 | m_newlife_cardpz | 6 | 1, 2, 3, 4, 5, 6 |
| 4 | m_newlife_needdrug | 39 | 10, 20, 40, 60, 80, 100 |
| 5 | m_newlife_needcards | 1 | 1 |

## newlifeprop (54 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 54 | 1, 2, 3, 4, 5, 6 |
| 2 | m_newlife_nijia_pinzhi | 6 | 1, 2, 3, 4, 5, 6 |
| 3 | m_newlife_times | 9 | 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 |
| 4 | m_newlife_times_basis | 9 | 0.15, 0.35, 0.5, 0.7, 0.95, 1.2 |
| 5 | m_newlife_times_grow | 9 | 0.15, 0.35, 0.5, 0.7, 0.95, 1.2 |
| 6 | m_newlife_times_control | 7 | 0.05, 0.1, 0.2, 0.25, 0.3, 0.35 |
| 7 | m_newlife_times_skill | 7 | 0.03, 0.06, 0.1, 0.12, 0.14, 0.16 |
| 8 | m_newlife_times_exp | 9 | 0.5, 1.0, 3.0, 5.0, 8.0, 10.0 |
| 9 | m_newlife_times_proexp | 9 | 0.5, 1.0, 3.0, 5.0, 8.0, 10.0 |
| 10 | m_newlife_times_needmoney | 9 | 0.5, 1.0, 3.0, 5.0, 8.0, 10.0 |

## ninjabookrank (287 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 287 | 1, 2, 3, 4, 5, 6 |
| 2 | m_icon | 207 | npc300_16, npc300_19, npc300_2, npc300_20, npc300_15, npc300_1 |
| 3 | m_ninjaid1 | 287 | 5038, 5059, 5002, 5062, 5035, 2083 |
| 4 | m_ninjaid2 | 207 | 5039, 5060, 5003, 5063, 5036, 2084 |

## ninjafiveprop (5 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 5 | 1, 2, 3, 4, 5 |
| 2 | m_propname | 5 | Water, Fire, Wind, Earth, Thunder |
| 3 | m_limitedid | 5 | 2, 3, 5, 1, 4 |
| 4 | m_limitedname | 5 | Fire, Wind, Thunder, Water, Earth |
| 5 | m_invokeratio | 1 | 1.0 |
| 6 | m_limitedval | 1 | 0.15 |

## ninjainfo (2546 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 2546 | 1, 2, 3, 4, 5, 6 |
| 2 | m_ninjaname | 406 | Sage of the Six Paths, Uchiha Madara, Hashirama Senju, Uchiha Obito, Naruto Uzumaki, Itachi Uchiha |
| 3 | m_ninjaicon | 252 | npc14_4, npc17_4, npc02_4, npc16_4, npc30_6, npc15_2 |
| 4 | m_calctype | 2 | 1, 0 |
| 5 | m_ninjarank | 164 | 1, 2, 3, 4, 5, 6 |
| 6 | m_ninjaattacktype | 3 | 0, 1, 2 |
| 7 | m_level | 152 | 1, 0, 2, 5, 10, 13 |
| 8 | m_weaponid | 1 | 0 |
| 9 | m_armorid | 1 | 0 |
| 10 | m_adornmentid | 1 | 0 |
| 11 | m_quality | 7 | 5, 4, 3, 2, 1, 0 |
| 12 | m_ninjutsu1 | 36 | 0, 65, 59, 56, 68, 73 |
| 13 | m_ninjutsu2 | 1 | 0 |
| 14 | m_ninjutsu3 | 1 | 0 |
| 15 | m_ninjutsu4 | 1 | 0 |
| 16 | m_ninjadesc | 319 | He was sometimes said to be the Creator , Chieftain of Uchiha branch and founder o, Chieftain of Senju branch and founder of, Studied under Minato Namikaze with Kakas, With Evil Kyubi sealed inside, he, who l, The genius shinobi of the Uchiha, a nobl |
| 17 | m_ninjafightwords | 178 | Nothing can escape the control of the Ri, This world is so small it is only enough, Nobody can destroy the Konohagakure whic, Compared to this battle, nothing else ma, I will never give up, because that it my, In Tsukuyomi's world, everything is in m |
| 18 | m_desc_from | 1 |  |
| 19 | m_attackmin | 229 | 528, 442, 458, 464, 470, 466 |
| 20 | m_attackmax | 282 | 720, 580, 550, 530, 510, 500 |
| 21 | m_defensemin | 229 | 316, 265, 274, 278, 282, 279 |
| 22 | m_defensemax | 281 | 432, 348, 330, 318, 306, 300 |
| 23 | m_chakrasmin | 193 | 369, 310, 321, 325, 329, 327 |
| 24 | m_chakrasmax | 212 | 504, 406, 385, 371, 357, 350 |
| 25 | m_attackmin_upgrade | 40 | 39, 30, 31, 29, 32, 26 |
| 26 | m_attackmax_upgrade | 47 | 48, 42, 40, 41, 39, 38 |
| 27 | m_defensemin_upgrade | 40 | 24, 18, 19, 20, 16, 17 |
| 28 | m_defensemax_upgrade | 47 | 28, 26, 24, 25, 23, 22 |
| 29 | m_chakrasmin_upgrade | 40 | 28, 21, 22, 23, 19, 20 |
| 30 | m_chakrasmax_upgrade | 47 | 33, 30, 28, 29, 27, 26 |
| 31 | m_npc_attackmin | 340 | 25, 0, 418, 459, 500, 541 |
| 32 | m_npc_attackmax | 344 | 30, 0, 525, 575, 626, 677 |
| 33 | m_npc_defensemin | 815 | 25, 184, 189, 338, 194, 197 |
| 34 | m_npc_defensemax | 815 | 30, 244, 249, 443, 248, 251 |
| 35 | m_npc_chakrasmin | 2 | 30, 0 |
| 36 | m_npc_chakrasmax | 2 | 35, 0 |
| 37 | m_cuilian1 | 122 | Chakra+275, Chakra+227, Chakra+224, Chakra+221, Chakra+218, Chakra+214 |
| 38 | m_cuilian2 | 241 | Attack+275, Attack+227, Attack+224, Attack+221, Attack+218, Attack+214 |
| 39 | m_cuilian3 | 256 | Defense+330, Defense+273, Defense+269, Defense+265, Defense+261, Defense+257 |
| 40 | m_cuilian4 | 331 | Max Attack+921, Max Attack+765, Max Attack+785, Max Attack+791, Max Attack+753, Max Attack+761 |
| 41 | m_zhuansheng1 | 230 | Attack+206, Attack+170, Attack+168, Attack+165, Attack+163, Attack+161 |
| 42 | m_zhuansheng2 | 232 | Attack+230, Attack+204, Attack+201, Attack+199, Attack+196, Attack+193 |
| 43 | m_zhuansheng3 | 245 | Attack+371, Attack+307, Attack+302, Attack+298, Attack+294, Attack+290 |
| 44 | m_lianhua_pinzhi | 5 | 6, 5, 4, 3, 0 |

## ninjamatch (1910 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 1910 | 1, 2, 3, 4, 5, 6 |
| 2 | m_matchname | 6 | 1, 2, 3, 4, 5, 6 |
| 3 | m_ninja_id | 430 | 1, 2, 3, 4, 5, 6 |
| 4 | m_matchdesc | 1071 | Top shinobi grant s all Shinobi  +15% AT, Equip Bashōsen +25% ATK, Fight with Ten Tails +30% ATK, Equipt Ninjutsu The Six Paths Rinnegan +, Fight with Madara +20% ATK, Fight with Uchiha Obito +25% ATK |
| 5 | m_effecttype | 2 | 0, 1 |
| 6 | m_ninja_1 | 121 | 0, 15, 2, 4, 3, 14 |
| 7 | m_ninja_2 | 82 | 0, 154, 156, 155, 182, 187 |
| 8 | m_ninja_3 | 61 | 0, 2031, 2033, 2032, 2064, 2057 |
| 9 | m_ninja_4 | 45 | 0, 5041, 2018, 2086, 2022, 2080 |
| 10 | m_ninja_5 | 127 | 0, 167, 5042, 2020, 2087, 166 |
| 11 | m_ninja_6 | 72 | 0, 5043, 2023, 2088, 5012, 2082 |
| 12 | m_ninja_7 | 48 | 0, 2026, 5013, 5020, 2111, 2081 |
| 13 | m_ninja_8 | 44 | 0, 2027, 5021, 5009, 2105, 5031 |
| 14 | m_equipid | 57 | 0, 1, 35, 34, 59, 2 |
| 15 | m_skillid | 45 | 0, 52, 42, 47, 49, 40 |
| 16 | m_attack_ratio | 18 | 0.15, 0.25, 0.3, 0.2, 0.11, 0.1 |
| 17 | m_defense_ratio | 18 | 0.15, 0.0, 0.11, 0.1, 0.05, 0.25 |
| 18 | m_chakra_ratio | 8 | 0.0, 0.4, 0.3, 0.25, 0.2, 0.15 |
| 19 | m_effect_skill | 1 | 0.0 |

## ninjastrength (30 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 30 | 1, 2, 3, 4, 5, 6 |
| 2 | m_strengthlevel | 15 | 0, 1, 2, 3, 4, 5 |
| 3 | m_stroneratio1 | 14 | 60, 50, 20, 5, 3, 2 |
| 4 | m_stroneratio2 | 18 | 65, 55, 25, 10, 5, 4 |
| 5 | m_stroneratio3 | 18 | 70, 60, 30, 15, 7, 6 |
| 6 | m_stroneratio4 | 19 | 75, 65, 35, 20, 9, 8 |
| 7 | m_nocutclevel | 7 | 100, 80, 60, 20, 10, 1 |
| 8 | m_cuttolevel | 7 | 0, 3, 6, 9, 10, 12 |
| 9 | m_needsilver | 15 | 50, 100, 150, 200, 250, 300 |

## ninjastrengthconfig (15 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 15 | 1, 2, 3, 4, 5, 6 |
| 2 | m_addprop | 15 | 0.05, 0.1, 0.2, 0.25, 0.3, 0.4 |

## ninjaupgrade (50 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 50 | 1, 2, 3, 4, 5, 6 |
| 2 | m_needexp | 49 | 50, 100, 150, 200, 250, 300 |
| 3 | m_costexp | 50 | 75, 100, 150, 250, 375, 525 |
| 4 | m_needsilver | 50 | 150, 200, 300, 500, 750, 1050 |
| 5 | m_sellprice | 50 | 50, 100, 150, 200, 250, 300 |

## ninjiasoulconfig (8 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 8 | 1, 2, 3, 4, 5, 6 |
| 2 | m_ninjiasoul_icon | 8 | props_135, props_136, props_137, props_138, props_094, props_093 |
| 3 | m_ninjiasoul_drop | 8 | 524, 525, 526, 527, 344, 345 |
| 4 | m_ninjiasoul_exchange | 2 | 6, 0 |
| 5 | m_ninjiasoul_print | 1 | 1 |
| 6 | m_ninjiasoul_propsID | 2 | 25, 0 |
| 7 | m_ninjiasoul_propsnum | 8 | 1, 2, 3, 4, 2000, 5000 |
| 8 | m_ninjiasoul_type | 3 | 1, 2, 3 |

## ninjutsubookrank (56 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 56 | 1, 2, 3, 4, 5, 6 |
| 2 | m_icon | 55 | skill_012, skill_051, skill_052, skill_050, skill_018, skill_019 |
| 3 | m_ninjutsuid | 56 | 52, 51, 50, 49, 48, 47 |

## ninjutsuinfo (91 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 91 | 1, 2, 3, 4, 5, 6 |
| 2 | m_ninjutsuName | 57 | Colone Technique, Body Replacement Technique, Hiding technique, Water Dragon Bullet, Secret Technique Attack, Genjutsu Attack |
| 3 | m_skilltype | 1 | 0 |
| 4 | m_rate | 2 | 0.15, 1.0 |
| 5 | m_quality | 5 | 1, 2, 3, 4, 5 |
| 6 | m_level | 2 | 1, 3 |
| 7 | m_effectid | 44 | , shoulijian.ccbi, SoftBoxing.ccbi, haohuoshu.ccbi, SuperPower.ccbi, kuileishu.ccbi |
| 8 | m_targetcount | 1 | 1 |
| 9 | m_effectcamp | 1 | 111111 |
| 10 | m_attackvalue | 56 | 15, 16, 18, 19, 21, 22 |
| 11 | m_add_attack | 1 | 0 |
| 12 | m_add_defense | 1 | 0 |
| 13 | m_add_chakras | 1 | 0 |
| 14 | m_reduce_attack | 1 | 0 |
| 15 | m_reduce_defecse | 1 | 0 |
| 16 | m_reduce_repeat_attack | 1 | 0 |
| 17 | m_reduce_repeat_defense | 1 | 0 |
| 18 | m_attackvalue_up | 13 | 1, 2, 4, 3, 5, 6 |
| 19 | m_add_attack_up | 1 | 0 |
| 20 | m_add_defense_up | 1 | 0 |
| 21 | m_add_chakras_up | 1 | 0 |
| 22 | m_reduce_attack_up | 1 | 0 |
| 23 | m_reduce_defecse_up | 1 | 0 |
| 24 | m_reduce_repeat_attack_up | 1 | 0 |
| 25 | m_reduce_repeat_defense_up | 1 | 0 |
| 26 | m_price | 1 | 20 |
| 27 | m_descinfo | 57 | Uses own Chakra to create an identical c, Immediately teleports, exchanging plant , Use Chakra to hide yourself and wait for, Suiton Ninjutsu that allows the user to , Uses Secret Technique Attack, impossible, Uses Genjutsu Attack to confuse enemies. |
| 28 | m_icon | 55 | skill_023, skill_024, skill_022, skill_032, skill_036, skill_037 |
| 29 | m_skill_suit | 7 | 0, 6, 5, 4, 3, 2 |

## ninjutsuupgrade (50 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 50 | 1, 2, 3, 4, 5, 6 |
| 2 | m_needexp | 49 | 50, 100, 150, 200, 250, 300 |
| 3 | m_costexp | 50 | 250, 350, 500, 600, 675, 945 |
| 4 | m_needsilver | 50 | 125, 175, 250, 300, 337, 472 |
| 5 | m_sellprice | 50 | 50, 100, 150, 200, 250, 300 |

## normalconfig (303 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 303 | 1, 2, 3, 4, 5, 6 |
| 2 | m_configdesc | 303 | 查克拉伤害值, 碎片合成时间（秒）, pk间隔等级, pk前多少级, 默认复活次数, 默认最大被攻击次数 |
| 3 | m_configval | 93 | 200, 1800, 20, 30, 10, 5000 |

## packtips (6 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 6 | 1, 2, 3, 4, 5, 6 |
| 2 | m_tipwords | 3 | Come from training, lucky draw, advancin, Come from sparring, shop, or arena gifts, Come from plundering other players' card |
| 3 | m_topage | 3 | 1, 2, 3 |
| 4 | m_storetab | 3 | 1, 2, 3 |
| 5 | m_goossid | 6 | 1, 7, 8, 9, 13, 0 |

## petinfo (8 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 8 | 1, 2, 3, 4, 5, 6 |
| 2 | m_pet_name | 8 | Gamakichi, Pakkun, Ningame, Kamatari, Manda, Aoda |
| 3 | m_pet_icon | 8 | npc23_3, npc46_9, npc46_8, npc300_21, npc20_3, npc300_22 |
| 4 | m_pet_skillicon | 1 | petskill_001 |
| 5 | m_pet_skillname | 1 | beast hit |
| 6 | m_pet_skilldes | 1 | 1/3 chance cause %d damage to enemies |
| 7 | m_pet_skilleff | 8 | pet_anim_1, pet_anim_2, pet_anim_3, pet_anim_4, pet_anim_5, pet_anim_6 |
| 8 | m_pet_quality | 2 | 4, 5 |
| 9 | m_pet_att | 8 | 870, 850, 950, 880, 970, 975 |
| 10 | m_pet_def | 8 | 660, 640, 740, 680, 760, 765 |
| 11 | m_pet_cha | 7 | 700, 680, 780, 720, 785, 790 |
| 12 | m_pet_skillatt | 8 | 185, 175, 200, 190, 210, 215 |
| 13 | m_pet_levelatt | 2 | 150, 100 |
| 14 | m_pet_leveldef | 2 | 100, 150 |
| 15 | m_pet_levelcha | 2 | 80, 100 |
| 16 | m_pet_levelskill | 2 | 5, 7 |
| 17 | m_pet_baselevel | 1 | 1 |
| 18 | m_pet_basestar | 1 | 0 |
| 19 | m_pet_baseequ | 1 | 0 |
| 20 | m_pet_gen | 1 | 100 |
| 21 | m_pet_gencrit | 1 | 20 |
| 22 | m_pet_genexpend | 1 | 150 |
| 23 | m_pet_spe | 1 | 100 |
| 24 | m_pet_specrit | 1 | 50 |
| 25 | m_pet_speexpend | 1 | 30 |
| 26 | m_pet_speexpendadd | 1 | 30 |
| 27 | m_pet_speexpendcei | 1 | 150 |
| 28 | m_pet_des | 8 | occasional showing up during one of Naru, one of eight dogs summoned by Kakashi,he, summoned by Maito Gai with incredible po, Kamatari is a giant,white-furred weasel , Manda was very snobbish and proud,believ, Aoda is an inhabitant of the Ryūchi Cave |

## petupgrade (50 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_level_id | 50 | 1, 2, 3, 4, 5, 6 |
| 2 | m_level_itemid | 1 | 36 |
| 3 | m_level_itemnum | 7 | 20, 25, 30, 35, 40, 55 |

## petupgradeequ (10 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_equ_level | 10 | 1, 2, 3, 4, 5, 6 |
| 2 | m_equ_itemid | 1 | 37 |
| 3 | m_equ_itemnum | 10 | 50, 60, 70, 80, 100, 120 |
| 4 | m_equ_pro | 10 | 100, 80, 70, 60, 50, 40 |
| 5 | m_equ_att | 10 | 650, 1450, 2600, 4100, 5950, 8250 |
| 6 | m_equ_def | 10 | 650, 1450, 2600, 4100, 5950, 8250 |
| 7 | m_equ_cha | 10 | 650, 1450, 2600, 4100, 5950, 8250 |
| 8 | m_equ_name | 10 | ·Lv1, ·Lv2, ·Lv3, ·Lv4, ·Lv5, ·Lv6 |

## petupgradestar (10 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_star_level | 10 | 1, 2, 3, 4, 5, 6 |
| 2 | m_star_training | 10 | 1000, 1300, 1600, 1900, 2200, 2500 |
| 3 | m_star_attpro | 10 | 50, 200, 350, 500, 650, 800 |

## piece_info (372 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 372 | 1, 2, 3, 4, 5, 6 |
| 2 | m_piece_name | 287 | Sage of the Six Paths, Uchiha Madara, Hashirama Senju?, Uchiha Obito, Naruto Uzumaki, Itachi Uchiha |
| 3 | m_piece_type | 4 | 1, 4, 2, 5 |
| 4 | m_piece_subtype | 5 | 1, 2, 3, 0, 5 |
| 5 | m_piece_star | 4 | 5, 4, 6, 0 |
| 6 | m_piece_targetthingID | 311 | 1, 2, 3, 4, 5, 6 |
| 7 | m_piece_exchangenum | 3 | 30, 15, 50 |
| 8 | m_piece_drop | 371 | 952, 953, 954, 955, 956, 957 |

## playemedal (21 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 21 | 1, 2, 3, 4, 5, 6 |
| 2 | m_medalname | 21 | Junior Genin, Middle Genin, Senior Genin, Elite Genin, Junior Chūnin, Middle Chūnin |
| 3 | m_attackmin | 21 | 25, 50, 100, 150, 250, 350 |
| 4 | m_attackmax | 21 | 25, 50, 100, 150, 250, 350 |
| 5 | m_defensemin | 21 | 25, 50, 100, 150, 250, 350 |
| 6 | m_defensemax | 21 | 25, 50, 100, 150, 250, 350 |
| 7 | m_chakrasmin | 21 | 25, 50, 100, 150, 250, 350 |
| 8 | m_chakrasmax | 21 | 25, 50, 100, 150, 250, 350 |
| 9 | m_needmedal | 21 | 500, 1000, 2000, 4000, 8000, 12000 |
| 10 | m_merit_icon | 21 | com_medal_01, com_medal_02, com_medal_03, com_medal_04, com_medal_05, com_medal_06 |

## playerlevel (350 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 350 | 1, 2, 3, 4, 5, 6 |
| 2 | m_need_exp | 273 | 6, 9, 12, 15, 18, 21 |
| 3 | m_own_fightcount | 7 | 3, 4, 5, 6, 7, 8 |
| 4 | m_own_strengval | 187 | 10, 12, 14, 16, 18, 20 |
| 5 | m_teammemcount | 18 | 1, 2, 3, 4, 5, 6 |
| 6 | m_playerattack | 350 | 20, 31, 42, 53, 64, 75 |
| 7 | m_playerdefense | 350 | 20, 31, 42, 53, 64, 75 |
| 8 | m_plunder_winexp | 236 | 1, 2, 3, 4, 5, 6 |
| 9 | m_plunder_failexp | 80 | 1, 2, 3, 4, 5, 6 |
| 10 | m_plunder_winsilver | 1 | 0 |
| 11 | m_plunder_failsilver | 237 | 10, 12, 14, 16, 18, 20 |
| 12 | m_tower_winexp | 7 | 20, 30, 40, 50, 60, 70 |
| 13 | m_tower_failexp | 7 | 30, 45, 60, 75, 90, 105 |
| 14 | m_tower_winsilver | 1 | 15 |
| 15 | m_tower_failsilver | 1 | 15 |

## plunderinfo (700 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 700 | 1, 2, 3, 4, 5, 6 |
| 2 | m_leveldiff | 700 | 1, 2, 3, 4, 5, 6 |
| 3 | m_probability | 12 | 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 |
| 4 | m_prodesc | 6 | General, Higher, Shall, low, Very low, No |
| 5 | m_needfight | 1 | 1 |

## recruitinfo (3 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 3 | 1, 2, 3 |
| 2 | m_dropid | 3 | 1, 2, 3 |
| 3 | m_needgold | 3 | 300, 150, 1 |
| 4 | m_refresh | 3 | 3/0/0/0, 2/0/0/0, 0/0/15/0 |
| 5 | m_daylimit | 2 | 0, 5 |
| 6 | m_sixstart | 1 |  |
| 7 | m_fivestar | 2 | เป็นไปได้มาก,  |
| 8 | m_fourstar | 3 | การันตี, เป็นไปได้มาก, ความน่าจะเป็นที่เป็นไปได้ |
| 9 | m_threestar | 2 | , การันตี |
| 10 | m_twostar | 1 |  |

## refinery_info (4 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 4 | 1, 2, 3, 4 |
| 2 | m_item_type | 1 | 1 |
| 3 | m_item_quality | 4 | 6, 5, 4, 3 |
| 4 | m_item_count | 4 | 2000, 1000, 150, 0 |
| 5 | m_item_silvercost | 1 | 0 |
| 6 | m_item_dropid1 | 4 | 1157, 1158, 1335, 310 |
| 7 | m_item_dropid2 | 1 | 0 |

## roundinfo (1234 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 1234 | 1, 2, 3, 4, 5, 6 |
| 2 | m_roundid | 87 | 1, 2, 3, 4, 5, 6 |
| 3 | m_subroundid | 16 | 1, 2, 3, 4, 5, 6 |
| 4 | m_storyid | 19 | 1, 2, 3, 4, 5, 6 |
| 5 | m_roundname | 1122 | Book of Seal, Will of Kill, Exam, Stay Away, Dare You, Boss is Here |
| 6 | m_roundicon | 38 | level_01_01, level_02_01, level_02_02, level_02_03, level_02_04, level_03_01 |
| 7 | m_npc1 | 166 | 0, 3000, 3002, 3004, 3006, 3008 |
| 8 | m_npc2 | 165 | 0, 3333, 3003, 3005, 3007, 3009 |
| 9 | m_npc3 | 163 | 0, 3005, 3007, 3009, 3011, 3014 |
| 10 | m_npc4 | 161 | 0, 3009, 3011, 3014, 3015, 3017 |
| 11 | m_npc5 | 155 | 0, 3022, 3023, 3024, 3025, 3026 |
| 12 | m_npc6 | 142 | 0, 3038, 3039, 3041, 3043, 3047 |
| 13 | m_npc7 | 128 | 0, 3075, 3079, 3082, 3085, 3087 |
| 14 | m_npc8 | 96 | 0, 3159, 3160, 3162, 3164, 3166 |
| 15 | m_npc9 | 82 | 0, 3186, 3189, 3190, 3192, 3194 |
| 16 | m_npc10 | 72 | 0, 3330, 3208, 3210, 3212, 3216 |
| 17 | m_npc11 | 57 | 0, 3236, 3240, 3246, 3247, 3250 |
| 18 | m_npc12 | 50 | 0, 3256, 3259, 3262, 3264, 3265 |
| 19 | m_npc13 | 37 | 0, 3286, 3289, 3290, 3292, 3294 |
| 20 | m_npc14 | 29 | 0, 3299, 3301, 3303, 3306, 3309 |
| 21 | m_npc15 | 16 | 0, 3323, 3325, 3327, 3336, 3338 |
| 22 | m_needpower | 29 | 3, 2, 4, 5, 8, 9 |
| 23 | m_addexpnormal | 158 | 6, 4, 8, 10, 16, 18 |
| 24 | m_addsilvernormal | 179 | 15, 10, 20, 25, 40, 45 |
| 25 | m_dropid | 142 | 0, 827, 829, 828, 725, 830 |
| 26 | m_addexp | 158 | 6, 4, 8, 10, 16, 18 |
| 27 | m_addexprate | 3 | 0, 200, 1000 |
| 28 | m_addsilver | 179 | 15, 10, 20, 25, 40, 45 |
| 29 | m_addsilverrate | 1 | 2000 |
| 30 | m_chestid | 1 | 25 |
| 31 | m_chestrate | 1 | 1000 |
| 32 | m_addgold | 7 | 5, 10, 0, 15, 20, 25 |
| 33 | m_addgoldrate | 1 | 1 |
| 34 | m_addpower | 6 | 5, 10, 15, 20, 25, 30 |
| 35 | m_addpowerrate | 1 | 3 |
| 36 | m_norewardrate | 1 | 200 |
| 37 | m_rounddesc | 1234 | To gain the forbidden Ninjutsu in sealed, After your stealing of The Scroll of Sea, You learned Colone Technique and graduat, Ebisuthe private tutor of Konohamaru the, After knowing that you beated Konohamaru, Udon got beat by you and ran away saying |
| 38 | m_round_boss | 4 | 0, 1, 2, 3 |
| 39 | m_stage_id | 14 | 1, 2, 3, 4, 5, 6 |
| 40 | m_stage_name | 170 | Book, Dare You, Fate, Brothers, Sasuke, Real Ninja |
| 41 | m_advise_level | 149 | 0, 2, 5, 10, 13, 15 |
| 42 | m_limit_times | 4 | 2, 3, 1, 4 |
| 43 | m_npc_kill_needmoney | 4 | 0, 10, 15, 20 |
| 44 | m_drop_value_icon | 142 | , weapon_018, weapon_019, Armor_009, npc27_3, weapon_024 |
| 45 | m_drop_value_star | 4 | 0, 3, 4, 5 |
| 46 | m_drop_value_type1 | 3 | 0, 1, 2 |
| 47 | m_drop_value_id | 99 | 0, 18, 17, 45, 84, 9 |
| 48 | m_round_attack_kind | 1 | 0 |
| 49 | m_drop_value_type2 | 9 | 0, 2, 1, 4, 23, 15 |
| 50 | m_jiangli_name | 131 | , Thunderswords.Kiba, Blastsword.Shibuki, Sunagakure's Uniform, Ameyuri Ringo , Flying Thunder God.Kunai |

## rushtower (25 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 25 | 1, 2, 3, 4, 5, 6 |
| 2 | m_towername | 25 | Deepest Fond, Disaster, For Friendship, Lair of Orochimaru, On Mount Myōboku, Big Disaster |
| 3 | m_chestid | 1 | 0 |
| 4 | m_rewardsilver | 1 | 0 |
| 5 | m_rewardgold | 1 | 0 |
| 6 | m_rewardexp | 1 | 0 |
| 7 | m_towerdesc | 25 | The ambition-driven Zabuza finally reali, To get Sasuke, Orochimaru summoned Nidai, For more powerful strength, Sasuke ran a, To seek Sasuke, you, with Naruto and Sak, Sasuke didn't back with you in the end. , Akatsuki killed all residents of Konohag |
| 8 | m_tower_icon | 3 | Emigrated_007, Emigrated_019, Emigrated_004 |
| 9 | m_fill_id1 | 1 | 284 |
| 10 | m_fill_id2 | 1 | 285 |
| 11 | m_fill_id3 | 1 | 286 |
| 12 | m_fill_id4 | 1 | 288 |

## secret_shop (240 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 240 | 1, 2, 3, 4, 5, 6 |
| 2 | m_item_name | 72 | Second Tsuchikage, Second Mizukage, Fourth Kumogakure, Onoki, Hiruzen Sarutobi, Fukasaku |
| 3 | m_item_type | 3 | 1, 5, 2 |
| 4 | m_item_subtype | 7 | 1, 0, 8, 11, 36, 37 |
| 5 | m_item_target | 115 | 18, 19, 20, 21, 22, 23 |
| 6 | m_item_num | 10 | 1, 3, 5, 10, 20, 30 |
| 7 | m_item_costtype | 1 | 1 |
| 8 | m_item_cost | 24 | 5000, 4000, 270, 170, 130, 500 |
| 9 | m_item_ratio | 30 | 500, 600, 1000, 1500, 2100, 4500 |
| 10 | m_item_dropid | 218 | 969, 970, 971, 972, 973, 974 |

## sevendays_info (7 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 7 | 1, 2, 3, 4, 5, 6 |
| 2 | m_sevendays_num | 7 | 1, 2, 3, 4, 5, 6 |
| 3 | m_sevendays_quest_id1 | 7 | 1, 2, 4, 15, 9, 16 |
| 4 | m_sevendays_quest_id2 | 7 | 0, 3, 5, 8, 7, 12 |
| 5 | m_sevendays_quest_id3 | 6 | 0, 6, 13, 11, 14, 18 |
| 6 | m_sevendays_drop1 | 7 | 1446, 1448, 1449, 1450, 1447, 1451 |
| 7 | m_sevendays_pic1 | 7 | props_189, props_185, props_186, props_190, props_187, props_188 |
| 8 | m_sevendays_dropnum1 | 1 | 1 |
| 9 | m_sevendays_drop2 | 5 | 506, 270, 114, 1452, 242 |
| 10 | m_sevendays_pic2 | 5 | props_036, props_034, props_208, props_170, props_035 |
| 11 | m_sevendays_dropnum2 | 5 | 30000, 50, 40, 15, 100 |
| 12 | m_sevendays_drop3 | 7 | 0, 506, 1397, 1398, 241, 1306 |
| 13 | m_sevendays_pic3 | 5 | , props_036, props_170, props_035, props_169 |
| 14 | m_sevendays_dropnum3 | 6 | 0, 30000, 5, 10, 50, 30 |

## sevendays_quest (23 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 23 | 1, 2, 3, 4, 5, 6 |
| 2 | m_sevendays_quest_tape | 16 | 1, 2, 3, 4, 5, 6 |
| 3 | m_spec | 23 | ผู้เล่นเข้าถึงเลเวล70, เข้าถึงนินจาชั้นสูงสุดในทีมได้เข้าถึงเลเ, กลายเป็นVIP1, มีนินจาที่ผ่านการแปรธาตุเลเวล5, ผ่าน“การทดสอบนินจา”ทั้งหมดทุกด่าน, ระดับชั้นนินจาเข้าถึงเกะนินชั้นกลาง |
| 4 | m_sevendays_quest_num | 17 | 70, 50, 1, 5, 72, 2 |

## skill_suit_info (13 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 13 | 1, 2, 3, 4, 5, 6 |
| 2 | m_se_suit_name | 13 | Six Paths, Technique, Fire Earth, Stunt, Bloodline, Chakra |
| 3 | m_se_suit_skype | 2 | 1, 2 |
| 4 | m_se_suit_param1 | 13 | 52, 46, 35, 37, 27, 25 |
| 5 | m_se_suit_param2 | 12 | 51, 44, 33, 36, 26, 24 |
| 6 | m_se_suit_param3 | 13 | 49, 43, 31, 32, 23, 21 |
| 7 | m_se_suit_param4 | 13 | 48, 42, 29, 28, 22, 20 |
| 8 | m_se_suit_attack2_num | 6 | 250, 200, 100, 50, 0, 150 |
| 9 | m_se_suit_attack2_percent | 4 | 0.0, 0.15, 0.1, 0.05 |
| 10 | m_se_suit_attack3_num | 6 | 350, 300, 100, 50, 0, 200 |
| 11 | m_se_suit_attack3_percent | 3 | 0.0, 0.15, 0.1 |
| 12 | m_se_suit_attack4_num | 8 | 450, 400, 150, 50, 0, 250 |
| 13 | m_se_suit_attack4_percent | 3 | 0.0, 0.15, 0.1 |
| 14 | m_se_suit_defence_num2 | 6 | 250, 200, 100, 50, 0, 150 |
| 15 | m_se_suit_defence_percent2 | 4 | 0.0, 0.15, 0.1, 0.05 |
| 16 | m_se_suit_defence_num3 | 5 | 300, 100, 50, 0, 200 |
| 17 | m_se_suit_defence_percent3 | 3 | 0.0, 0.15, 0.1 |
| 18 | m_se_suit_defence_num4 | 8 | 450, 400, 100, 50, 0, 250 |
| 19 | m_se_suit_defence_percent4 | 3 | 0.0, 0.15, 0.1 |
| 20 | m_se_suit_chackra_num2 | 4 | 0, 150, 100, 50 |
| 21 | m_se_suit_chackra_percent2 | 4 | 0.0, 0.15, 0.1, 0.05 |
| 22 | m_se_suit_chackra_num3 | 3 | 0, 200, 100 |
| 23 | m_se_suit_chackra_percent3 | 3 | 0.0, 0.15, 0.1 |
| 24 | m_se_suit_chackra_num4 | 5 | 0, 250, 300, 100, 150 |
| 25 | m_se_suit_chackra_percent4 | 3 | 0.0, 0.15, 0.1 |
| 26 | m_se_suit_skill_percent2 | 2 | 0.01, 0.0 |
| 27 | m_se_suit_skill_percent3 | 3 | 0.02, 0.01, 0.0 |
| 28 | m_se_suit_skill_percent4 | 3 | 0.02, 0.01, 0.0 |

## storyinfo (24 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 24 | 1, 2, 3, 4, 5, 6 |
| 2 | m_storyname | 20 | Shinobi Exams, Land of Waves, Chunin Test, Elite VS Elite, Defence, New Hokage |
| 3 | m_storyicon | 24 | 1, 2, 3, 4, 5, 6 |
| 4 | m_reward_gold_1 | 1 | 0 |
| 5 | m_reward_gold_2 | 1 | 0 |
| 6 | m_reward_gold_3 | 1 | 0 |
| 7 | m_reward_gold_4 | 1 | 0 |
| 8 | m_reward_gold_5 | 1 | 0 |
| 9 | m_reward_gold_6 | 1 | 0 |
| 10 | m_reward_gold_7 | 1 | 0 |
| 11 | m_reward_gold_8 | 1 | 0 |
| 12 | m_reward_gold_9 | 1 | 0 |
| 13 | m_reward_gold_10 | 1 | 0 |
| 14 | m_reward_gold_11 | 1 | 0 |
| 15 | m_reward_gold_12 | 1 | 0 |
| 16 | m_reward_gold_13 | 1 | 0 |
| 17 | m_reward_gold_14 | 1 | 0 |
| 18 | m_reward_gold_15 | 1 | 0 |
| 19 | m_reward_silver_1 | 19 | 200, 250, 300, 350, 400, 450 |
| 20 | m_reward_silver_2 | 19 | 250, 300, 350, 400, 450, 500 |
| 21 | m_reward_silver_3 | 19 | 350, 400, 450, 500, 550, 600 |
| 22 | m_reward_silver_4 | 19 | 450, 500, 550, 600, 650, 700 |
| 23 | m_reward_silver_5 | 19 | 550, 600, 650, 700, 750, 800 |
| 24 | m_reward_silver_6 | 19 | 650, 700, 750, 800, 850, 900 |
| 25 | m_reward_silver_7 | 19 | 750, 800, 850, 900, 950, 1000 |
| 26 | m_reward_silver_8 | 19 | 850, 900, 950, 1000, 1050, 1100 |
| 27 | m_reward_silver_9 | 19 | 950, 1000, 1050, 1100, 1150, 1200 |
| 28 | m_reward_silver_10 | 19 | 1050, 1100, 1150, 1200, 1250, 1300 |
| 29 | m_reward_silver_11 | 19 | 1150, 1200, 1250, 1300, 1350, 1400 |
| 30 | m_reward_silver_12 | 19 | 1250, 1300, 1350, 1400, 1450, 1500 |
| 31 | m_reward_silver_13 | 19 | 1350, 1400, 1450, 1500, 1550, 1600 |
| 32 | m_reward_silver_14 | 19 | 1450, 1500, 1550, 1600, 1650, 1700 |
| 33 | m_reward_silver_15 | 19 | 1550, 1600, 1650, 1700, 1750, 1800 |
| 34 | m_reward_exp_1 | 19 | 50, 80, 110, 140, 170, 200 |
| 35 | m_reward_exp_2 | 19 | 80, 110, 140, 170, 200, 230 |
| 36 | m_reward_exp_3 | 19 | 110, 140, 170, 200, 230, 260 |
| 37 | m_reward_exp_4 | 19 | 140, 170, 200, 230, 260, 290 |
| 38 | m_reward_exp_5 | 19 | 170, 200, 230, 260, 290, 320 |
| 39 | m_reward_exp_6 | 19 | 200, 230, 260, 290, 320, 350 |
| 40 | m_reward_exp_7 | 19 | 230, 260, 290, 320, 350, 380 |
| 41 | m_reward_exp_8 | 19 | 260, 290, 320, 350, 380, 410 |
| 42 | m_reward_exp_9 | 19 | 290, 320, 350, 380, 410, 440 |
| 43 | m_reward_exp_10 | 19 | 320, 350, 380, 410, 440, 470 |
| 44 | m_reward_exp_11 | 19 | 350, 380, 410, 440, 470, 500 |
| 45 | m_reward_exp_12 | 19 | 380, 410, 440, 470, 500, 530 |
| 46 | m_reward_exp_13 | 19 | 410, 440, 470, 500, 530, 560 |
| 47 | m_reward_exp_14 | 19 | 440, 470, 500, 530, 560, 590 |
| 48 | m_reward_exp_15 | 19 | 470, 500, 530, 560, 590, 620 |
| 49 | m_drop_1 | 1 | 268 |
| 50 | m_drop_2 | 1 | 268 |
| 51 | m_drop_3 | 1 | 268 |
| 52 | m_drop_4 | 1 | 268 |
| 53 | m_drop_5 | 1 | 268 |
| 54 | m_drop_6 | 1 | 268 |
| 55 | m_drop_7 | 1 | 268 |
| 56 | m_drop_8 | 1 | 268 |
| 57 | m_drop_9 | 1 | 268 |
| 58 | m_drop_10 | 1 | 268 |
| 59 | m_drop_11 | 1 | 268 |
| 60 | m_drop_12 | 1 | 268 |
| 61 | m_drop_13 | 1 | 268 |
| 62 | m_drop_14 | 1 | 268 |
| 63 | m_drop_15 | 1 | 268 |

## suit_info (56 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 56 | 1, 2, 3, 4, 5, 6 |
| 2 | m_suit_type | 2 | 1, 2 |
| 3 | m_suit_param | 5 | 4, 5, 6, 9, 12 |
| 4 | m_suit_num | 8 | 5, 7, 9, 12, 15, 17 |
| 5 | m_suit_attack_num | 35 | 1200, 1400, 1600, 1800, 2000, 2400 |
| 6 | m_suit_attack_percent | 18 | 0.02, 0.03, 0.04, 0.05, 0.06, 0.07 |
| 7 | m_suit_defense_num | 35 | 1200, 1400, 1600, 1800, 2000, 2400 |
| 8 | m_suit_defense_percent | 18 | 0.02, 0.03, 0.04, 0.05, 0.06, 0.07 |
| 9 | m_suit_chacra_num | 35 | 1200, 1400, 1600, 1800, 2000, 2400 |
| 10 | m_suit_chacra_percent | 18 | 0.02, 0.03, 0.04, 0.05, 0.06, 0.07 |
| 11 | m_suit_first | 32 | 1, 2, 3, 4, 5, 6 |
| 12 | m_suit_desc | 56 | 5 Four-Star Cards , 7 Four-Star Cards , 9 Four-Star Cards , 12 Four-Star Cards , 15 Four-Star Cards , 17 Four-Star Cards  |
| 13 | m_suit_small_up | 35 | 1, 2, 3, 4, 5, 6 |
| 14 | m_suit_small_down | 35 | 2, 3, 4, 5, 6, 7 |
| 15 | m_suit_big_up | 35 | 9, 10, 11, 12, 13, 14 |
| 16 | m_suit_big_down | 35 | 10, 11, 12, 13, 14, 15 |

## sysnotice (6 rows) — NOT read by the server

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 6 | 1, 2, 3, 4, 5, 6 |
| 2 | m_noticecontent | 6 | Thank you for accompanying Hokage sama, , 【Note】The GM will not ask for your accou, You can click on the national treasure b, Entering into war interface, you can be , 进入国战界面，可以成为本国的影者跟官员，还可以打国战！, 国庆期间充值，充多少夺宝，送多少元宝！充值就送！ |

## tower_reward (25 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 25 | 1, 2, 3, 4, 5, 6 |
| 2 | m_pass_num | 25 | 7, 14, 21, 28, 35, 42 |
| 3 | m_pass_drop1 | 7 | 100, 501, 134, 1362, 1363, 1364 |
| 4 | m_pass_drop1_description | 7 | 289, 290, 291, 292, 293, 294 |
| 5 | m_pass_drop2 | 6 | 380, 1314, 933, 913, 932, 108 |
| 6 | m_pass_drop2_description | 6 | 296, 297, 298, 299, 300, 301 |
| 7 | m_pass_drop3 | 22 | 691, 676, 694, 1321, 702, 708 |
| 8 | m_pass_drop3_description | 22 | 167, 192, 206, 282, 243, 242 |

## towerfloor (175 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 175 | 1, 2, 3, 4, 5, 6 |
| 2 | m_towerid | 25 | 1, 2, 3, 4, 5, 6 |
| 3 | m_bk_icon | 1 |  |
| 4 | m_npc1 | 175 | 564, 565, 566, 567, 568, 569 |
| 5 | m_npc2 | 175 | 564, 565, 566, 739, 740, 741 |
| 6 | m_npc3 | 175 | 564, 565, 566, 739, 740, 741 |
| 7 | m_npc4 | 175 | 564, 565, 566, 739, 740, 741 |
| 8 | m_npc5 | 175 | 564, 565, 566, 739, 740, 741 |
| 9 | m_npc6 | 169 | 0, 571, 572, 743, 744, 745 |
| 10 | m_npc7 | 162 | 0, 578, 748, 749, 750, 751 |
| 11 | m_npc8 | 148 | 0, 759, 760, 761, 762, 763 |
| 12 | m_npc9 | 127 | 0, 780, 781, 782, 783, 784 |
| 13 | m_npc10 | 106 | 0, 634, 796, 797, 798, 799 |
| 14 | m_npc11 | 78 | 0, 662, 663, 664, 823, 824 |
| 15 | m_npc12 | 64 | 0, 676, 829, 830, 831, 832 |
| 16 | m_npc13 | 43 | 0, 697, 698, 699, 845, 846 |
| 17 | m_npc14 | 25 | 0, 715, 856, 857, 718, 719 |
| 18 | m_npc15 | 8 | 0, 865, 866, 867, 868, 869 |
| 19 | m_needbody | 1 | 0 |
| 20 | m_addexp | 85 | 22, 24, 26, 60, 38, 40 |
| 21 | m_addsilver | 73 | 33, 36, 39, 57, 60, 63 |
| 22 | m_chestid | 26 | 914, 915, 916, 2, 181, 182 |
| 23 | m_floordesc | 139 | You have interrupted the master, you are, Everything will end now, die!, Not bad, you are quite good, but your lu, Argh, trapped by a few minions, such a d, Zabuza, surrender, or you will be finish, Master, run, I will block them for you. |
| 24 | m_attacktype | 2 | 0, 1 |

## vip_gift (25 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 25 | 1, 2, 3, 4, 5, 6 |
| 2 | m_vip_point | 20 | 10, 90, 300, 600, 1000, 1500 |
| 3 | m_vip_icon | 3 | props_192, props_264, props_263 |
| 4 | m_vip_dropid1 | 25 | 1393, 1376, 1378, 1379, 1380, 1384 |
| 5 | m_vip_dropid2 | 21 | 1395, 1394, 1399, 1400, 1401, 1402 |
| 6 | m_vip_dropid3 | 20 | 1397, 1395, 1396, 1415, 1416, 1417 |
| 7 | m_vip_dropid4 | 14 | 0, 1398, 1430, 1431, 1432, 1433 |
| 8 | m_vip_dropid5 | 1 | 0 |
| 9 | m_vip_cost | 21 | 30, 120, 200, 400, 600, 800 |
| 10 | m_vip_show | 25 | Silver*10000, Rāmen Ichiraku(L)*5, Recru, Kurama Seal, Silver*30000, Large Ramen*1, Yasaka Magatama, Refresh Order*10, Large, Uchiwa of Fire, Refresh Order*15, Reinca, Bashōsen, Refresh Order*20, Reincarnatio, Amaterasu, Refresh Order*25, Reincarnati |
| 11 | m_vip_original_cost | 25 | 115, 488, 800, 2150, 3375, 3950 |

## vipinfo (24 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 24 | 1, 2, 3, 4, 5, 6 |
| 2 | m_vip_props1_id | 1 | 4 |
| 3 | m_vip_props2_id | 1 | 5 |
| 4 | m_vip_props3_id | 1 | 0 |
| 5 | m_vip_props4_id | 1 | 0 |
| 6 | m_vip_props1_num | 24 | 20, 22, 24, 26, 28, 30 |
| 7 | m_vip_props2_num | 24 | 30, 33, 36, 39, 42, 45 |
| 8 | m_vip_props3_num | 1 | 0 |
| 9 | m_vip_props4_num | 1 | 0 |
| 10 | m_vip_props1_info | 24 | use 20 ramen daily, use 22 ramen daily, use 24 ramen daily, use 26 ramen daily, use 28 ramen daily, use 30 ramen daily |
| 11 | m_vip_props2_info | 24 | use 30 Hyourou-gan daily, use 33 Hyourou-gan daily, use 36 Hyourou-gan daily, use 39 Hyourou-gan daily, use 42 Hyourou-gan daily, use 45 Hyourou-gan daily |
| 12 | m_vip_props3_info | 1 |  |
| 13 | m_vip_props4_info | 1 |  |
| 14 | m_vip_fun1_ID | 1 | 1 |
| 15 | m_vip_fun2_ID | 1 | 2 |
| 16 | m_vip_fun3_ID | 1 | 3 |
| 17 | m_vip_fun4_ID | 1 | 4 |
| 18 | m_vip_fun5_ID | 1 | 0 |
| 19 | m_vip_fun6_ID | 1 | 0 |
| 20 | m_vip_fun7_ID | 1 | 7 |
| 21 | m_vip_fun1_num | 24 | 20, 21, 22, 23, 24, 25 |
| 22 | m_vip_fun2_num | 24 | 80, 85, 90, 95, 100, 105 |
| 23 | m_vip_fun3_num | 24 | 20, 25, 30, 35, 40, 45 |
| 24 | m_vip_fun4_num | 24 | 25, 30, 35, 40, 45, 50 |
| 25 | m_vip_fun5_num | 1 | 0 |
| 26 | m_vip_fun6_num | 1 | 0 |
| 27 | m_vip_fun7_num | 24 | 3, 4, 5, 6, 7, 8 |
| 28 | m_vip_fun1_info | 24 | attack 20 times in the arena daily, attack 21 times in the arena daily, attack 22 times in the arena daily, attack 23 times in the arena daily, attack 24 times in the arena daily, attack 25 times in the arena daily |
| 29 | m_vip_fun2_info | 24 | refresh the mystery shop 80 times daily, refresh the mystery shop 85 times daily, refresh the mystery shop 90 times daily, refresh the mystery shop 95 times daily, refresh the mystery shop 100 times daily, refresh the mystery shop 105 times daily |
| 30 | m_vip_fun3_info | 24 | monument can remove players 20 times, monument can remove players 25 times, monument can remove players 30 times, monument can remove players 35 times, monument can remove players 40 times, monument can remove players 45 times |
| 31 | m_vip_fun4_info | 24 | open gold chest 25 times, open gold chest 30 times, open gold chest 35 times, open gold chest 40 times, open gold chest 45 times, open gold chest 50 times |
| 32 | m_vip_fun5_info | 1 |  |
| 33 | m_vip_fun6_info | 1 |  |
| 34 | m_vip_fun7_info | 24 | 3 times for high level training per day, 4 times for high level training per day, 5 times for high level training per day, 6 times for high level training per day, 7 times for high level training per day, 8 times for high level training per day |

## warconfig (13 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 13 | 1, 2, 3, 4, 5, 6 |
| 2 | m_configname | 3 | Officer's Gift pack, Exchange gift pack, War victory |
| 3 | m_configtype | 3 | 1, 2, 3 |
| 4 | m_param1 | 9 | 1, 2, 3, 4, 5, 6 |
| 5 | m_param2 | 12 | 218, 219, 220, 1000, 3000, 4000 |
| 6 | m_param3 | 7 | 0, 361, 172, 363, 364, 362 |

## wealthactivity (8 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 8 | 1, 2, 3, 4, 5, 6 |
| 2 | m_godid | 1 | 3 |
| 3 | m_needgold | 8 | 25, 150, 250, 600, 1250, 2500 |
| 4 | m_minget | 8 | 30, 175, 300, 750, 1500, 3000 |
| 5 | m_maxget | 8 | 40, 185, 350, 800, 1550, 3100 |

## wheelconfig (12 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 12 | 1, 2, 3, 4, 5, 6 |
| 2 | m_wheel_icon | 12 | props_050, props_049, props_040, props_078, props_061, props_062 |
| 3 | m_wheel_name | 12 | 五星忍術, 四星忍術, 五星裝備, 轉生丹*1, 元寶*210, 五星忍者卡碎片*10 |
| 4 | m_wheel_drop | 12 | 14, 15, 13, 320, 137, 269 |
| 5 | m_wheel_percent | 9 | 500, 3000, 1000, 30000, 2000, 15000 |

## wheelpackconfig (8 rows)

| # | column | distinct | examples |
|---|---|---|---|
| 1 | m_id | 8 | 1, 2, 3, 4, 5, 6 |
| 2 | m_pack_wheel_name | 8 | 第1名, 第2-10名, 第11-50名, 第51-100名, 150分禮包, 400分禮包 |
| 3 | m_pack_wheel_icon | 8 | props_073, props_101, props_107, props_108, props_109, props_029 |
| 4 | m_pack_wheel_type | 2 | 1, 2 |
| 5 | m_pack_wheel_param1 | 8 | 374, 352, 371, 372, 150, 400 |
| 6 | m_pack_wheel_param2 | 5 | 0, 107, 283, 284, 11 |

