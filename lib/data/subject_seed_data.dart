import '../models/app_models.dart';

// Generated from SENARAI NAMA PENSYARAH & KURSUS YANG DIAJAR SESI JAN JUN 2026.xlsx.
// Only subjects for existing program master IDs are included; lecturer-course assignments are intentionally not seeded yet.
const subjectSeedTeachingRowsParsed = 368;
const subjectSeedRowsSkipped = 24;
const subjectSeedMissingProgramIds = ['DCW', 'SPN'];
const subjectSeedUniqueLecturerNamesFound = 116;

const subjectSeedData = <SubjectCourse>[
  SubjectCourse(
      subjectId: 'DCB_DLT20140',
      programId: 'DCB',
      subjectCode: 'DLT20140',
      subjectName: 'INDUSTRIAL PRACTICES 1'),
  SubjectCourse(
      subjectId: 'DCB_MEB10011',
      programId: 'DCB',
      subjectCode: 'MEB10011',
      subjectName: 'ELECTRICAL COMPETENCY FINAL PROJECT'),
  SubjectCourse(
      subjectId: 'DCB_MEB10022',
      programId: 'DCB',
      subjectCode: 'MEB10022',
      subjectName: 'DIESEL ENGINE GENERATOR'),
  SubjectCourse(
      subjectId: 'DCB_MEB10023',
      programId: 'DCB',
      subjectCode: 'MEB10023',
      subjectName: 'DIESEL ENGINE GENERATOR'),
  SubjectCourse(
      subjectId: 'DCB_MEB10034',
      programId: 'DCB',
      subjectCode: 'MEB10034',
      subjectName: 'GENERATION AND PARALLEL PROCEDURE'),
  SubjectCourse(
      subjectId: 'DCB_MEB10042',
      programId: 'DCB',
      subjectCode: 'MEB10042',
      subjectName: 'ELECTRICAL SUPPLY ACT AND REGULATION'),
  SubjectCourse(
      subjectId: 'DCB_MEB10053',
      programId: 'DCB',
      subjectCode: 'MEB10053',
      subjectName: 'ELECTRICAL ENERGY MANAGEMENT OPERATION'),
  SubjectCourse(
      subjectId: 'DCB_MEB10062',
      programId: 'DCB',
      subjectCode: 'MEB10062',
      subjectName: 'SOLAR INSTALLATION AND MAINTENANCE'),
  SubjectCourse(
      subjectId: 'DCB_MEB10112',
      programId: 'DCB',
      subjectCode: 'MEB10112',
      subjectName: 'GENERATION AND PARALLEL PROCEDURE'),
  SubjectCourse(
      subjectId: 'DCB_MEB10122',
      programId: 'DCB',
      subjectCode: 'MEB10122',
      subjectName: 'ELECTRICITY SUPPLY ACT AND REGULATION'),
  SubjectCourse(
      subjectId: 'DCB_MEB10132',
      programId: 'DCB',
      subjectCode: 'MEB10132',
      subjectName: 'ELECTRICAL ENERGY MANAGEMENT OPERATION'),
  SubjectCourse(
      subjectId: 'DCB_MEB10142',
      programId: 'DCB',
      subjectCode: 'MEB10142',
      subjectName: 'ELECTRICAL COMPETENCY FINAL PROJECT 1'),
  SubjectCourse(
      subjectId: 'DCB_NUK20032',
      programId: 'DCB',
      subjectCode: 'NUK20032',
      subjectName: 'DIGITAL ENTREPRENEURSHIP'),
  SubjectCourse(
      subjectId: 'DCB_NUS10081',
      programId: 'DCB',
      subjectCode: 'NUS10081',
      subjectName: 'TARBIAH MUSLIM'),
  SubjectCourse(
      subjectId: 'DCP_DLT30040',
      programId: 'DCP',
      subjectCode: 'DLT30040',
      subjectName: 'INDUSTRIAL TRAINING'),
  SubjectCourse(
      subjectId: 'DCP_DLT51040',
      programId: 'DCP',
      subjectCode: 'DLT51040',
      subjectName: 'INDUSTRIAL TRAINING'),
  SubjectCourse(
      subjectId: 'DCP_MEP20012',
      programId: 'DCP',
      subjectCode: 'MEP20012',
      subjectName: 'WORKSITE PROJECT MANAGEMENT'),
  SubjectCourse(
      subjectId: 'DCP_MEP20014',
      programId: 'DCP',
      subjectCode: 'MEP20014',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION AND MAINTENANCE 1'),
  SubjectCourse(
      subjectId: 'DCP_MEP40014',
      programId: 'DCP',
      subjectCode: 'MEP40014',
      subjectName: 'UNDERGROUND CABLE PRACTICES'),
  SubjectCourse(
      subjectId: 'DCP_MEP40024',
      programId: 'DCP',
      subjectCode: 'MEP40024',
      subjectName: 'LOW VOLTAGE SWITCHBOARD PRACTICES'),
  SubjectCourse(
      subjectId: 'DCP_MEP40034',
      programId: 'DCP',
      subjectCode: 'MEP40034',
      subjectName: 'AERIAL LINE PRACTICES'),
  SubjectCourse(
      subjectId: 'DCP_MEP40044',
      programId: 'DCP',
      subjectCode: 'MEP40044',
      subjectName: 'ELECTRICAL MAINTENANCE'),
  SubjectCourse(
      subjectId: 'DCP_MEP60014',
      programId: 'DCP',
      subjectCode: 'MEP60014',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION AND MAINTENANCE 2'),
  SubjectCourse(
      subjectId: 'DCP_MEP60044',
      programId: 'DCP',
      subjectCode: 'MEP60044',
      subjectName: 'ELECTRICAL COMPENTENCY FINAL PROJECT'),
  SubjectCourse(
      subjectId: 'DCP_MES10013',
      programId: 'DCP',
      subjectCode: 'MES10013',
      subjectName: 'ELECTRICAL INSTALLATION THEORY'),
  SubjectCourse(
      subjectId: 'DCP_MES10024',
      programId: 'DCP',
      subjectCode: 'MES10024',
      subjectName: 'ELECTRICAL INSTALLATION PRACTICE'),
  SubjectCourse(
      subjectId: 'DCP_MES10033',
      programId: 'DCP',
      subjectCode: 'MES10033',
      subjectName: 'ELECTRICAL PRINCIPLES 1'),
  SubjectCourse(
      subjectId: 'DCP_MES10042',
      programId: 'DCP',
      subjectCode: 'MES10042',
      subjectName: 'ELECTRICITY SUPPLY ACT AND REGULATIONS 1'),
  SubjectCourse(
      subjectId: 'DCP_MES20044',
      programId: 'DCP',
      subjectCode: 'MES20044',
      subjectName: 'ELECTRICAL MOTOR CONTROL'),
  SubjectCourse(
      subjectId: 'DCP_MES21033',
      programId: 'DCP',
      subjectCode: 'MES21033',
      subjectName: 'ELECTRICAL PRINCIPLE 2'),
  SubjectCourse(
      subjectId: 'DCP_MES41032',
      programId: 'DCP',
      subjectCode: 'MES41032',
      subjectName: 'ELECTRICITY SUPPLY ACT AND REGULATIONS 2'),
  SubjectCourse(
      subjectId: 'DCP_MES50033',
      programId: 'DCP',
      subjectCode: 'MES50033',
      subjectName: 'ELECTRICAL BULIDING AUTOMOTION SYSTEM INSTALLATION'),
  SubjectCourse(
      subjectId: 'DCP_MEV50053',
      programId: 'DCP',
      subjectCode: 'MEV50053',
      subjectName: 'INDUSTRIAL AUTOMATION'),
  SubjectCourse(
      subjectId: 'DCP_NUE30031',
      programId: 'DCP',
      subjectCode: 'NUE30031',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'DCP_NUE30051',
      programId: 'DCP',
      subjectCode: 'NUE30051',
      subjectName: 'ENGLISH FOR SOCIAL INTERACTION'),
  SubjectCourse(
      subjectId: 'DCP_NUE40000',
      programId: 'DCP',
      subjectCode: 'NUE40000',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'DCP_NUK20012',
      programId: 'DCP',
      subjectCode: 'NUK20012',
      subjectName: 'DIGITAL ENTREPRENEURSHIP'),
  SubjectCourse(
      subjectId: 'DCP_NUM10242',
      programId: 'DCP',
      subjectCode: 'NUM10242',
      subjectName: 'MATHEMATICS FOR ELECTRICAL'),
  SubjectCourse(
      subjectId: 'DCP_NUS10000',
      programId: 'DCP',
      subjectCode: 'NUS10000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DCP_NUS10022',
      programId: 'DCP',
      subjectCode: 'NUS10022',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DCP_NUS20000',
      programId: 'DCP',
      subjectCode: 'NUS20000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DCP_NUS40000',
      programId: 'DCP',
      subjectCode: 'NUS40000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DED_DED10044',
      programId: 'DED',
      subjectCode: 'DED10044',
      subjectName: 'ELECTRICAL INSTALLATION'),
  SubjectCourse(
      subjectId: 'DED_DED21052',
      programId: 'DED',
      subjectCode: 'DED21052',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION 1'),
  SubjectCourse(
      subjectId: 'DED_DED21064',
      programId: 'DED',
      subjectCode: 'DED21064',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION PRACTICE 1'),
  SubjectCourse(
      subjectId: 'DED_DED30073',
      programId: 'DED',
      subjectCode: 'DED30073',
      subjectName: 'INTRODUCTION TO DIGITAL ELECTRONICS'),
  SubjectCourse(
      subjectId: 'DED_DED31082',
      programId: 'DED',
      subjectCode: 'DED31082',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION 2'),
  SubjectCourse(
      subjectId: 'DED_DED31094',
      programId: 'DED',
      subjectCode: 'DED31094',
      subjectName: 'ELECTRICAL INDUSTRIAL INSTALLATION PRACTICE 2'),
  SubjectCourse(
      subjectId: 'DED_DED60114',
      programId: 'DED',
      subjectCode: 'DED60114',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'DED_DED60133',
      programId: 'DED',
      subjectCode: 'DED60133',
      subjectName: 'RENEWABLE ENERGY'),
  SubjectCourse(
      subjectId: 'DED_DED60144',
      programId: 'DED',
      subjectCode: 'DED60144',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'DED_DED61124',
      programId: 'DED',
      subjectCode: 'DED61124',
      subjectName: 'ADVANCE ELECTRICAL INSTALLATION'),
  SubjectCourse(
      subjectId: 'DED_DED61154',
      programId: 'DED',
      subjectCode: 'DED61154',
      subjectName: 'ADVANCE ELECTRICAL INSTALLATION'),
  SubjectCourse(
      subjectId: 'DED_DEV10043',
      programId: 'DED',
      subjectCode: 'DEV10043',
      subjectName: 'ELECTRICAL CIRCUIT THEORY 1'),
  SubjectCourse(
      subjectId: 'DED_DEV10052',
      programId: 'DED',
      subjectCode: 'DEV10052',
      subjectName: 'ELECTRICAL DRAWING'),
  SubjectCourse(
      subjectId: 'DED_DEV20072',
      programId: 'DED',
      subjectCode: 'DEV20072',
      subjectName: 'ELECTRICITY SUPPLY ACT AND REGULATIONS'),
  SubjectCourse(
      subjectId: 'DED_DEV20083',
      programId: 'DED',
      subjectCode: 'DEV20083',
      subjectName: 'ANALOGUE ELECTRONICS FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'DED_DEV31053',
      programId: 'DED',
      subjectCode: 'DEV31053',
      subjectName: 'ELECTRICAL MACHINE'),
  SubjectCourse(
      subjectId: 'DED_DEV40242',
      programId: 'DED',
      subjectCode: 'DEV40242',
      subjectName: 'ADVANCE ELECTRICAL DRAWING'),
  SubjectCourse(
      subjectId: 'DED_DEV40263',
      programId: 'DED',
      subjectCode: 'DEV40263',
      subjectName: 'INDUSTRIAL AUTOMATION'),
  SubjectCourse(
      subjectId: 'DED_DEV40273',
      programId: 'DED',
      subjectCode: 'DEV40273',
      subjectName: 'ELECTRICAL MOTOR CONTROL'),
  SubjectCourse(
      subjectId: 'DED_DEV40283',
      programId: 'DED',
      subjectCode: 'DEV40283',
      subjectName: 'POWER ELECTRONICS'),
  SubjectCourse(
      subjectId: 'DED_DEV41253',
      programId: 'DED',
      subjectCode: 'DEV41253',
      subjectName: 'ELECTRICAL CIRCUIT THEORY 2'),
  SubjectCourse(
      subjectId: 'DED_DKV10213',
      programId: 'DED',
      subjectCode: 'DKV10213',
      subjectName: 'ENGINEERING SCIENCE'),
  SubjectCourse(
      subjectId: 'DED_DKV40292',
      programId: 'DED',
      subjectCode: 'DKV40292',
      subjectName: 'PROJECT MANAGEMENT'),
  SubjectCourse(
      subjectId: 'DED_DUA20062',
      programId: 'DED',
      subjectCode: 'DUA20062',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'DED_DUB40072',
      programId: 'DED',
      subjectCode: 'DUB40072',
      subjectName: 'START- UP ENTERPRISE'),
  SubjectCourse(
      subjectId: 'DED_DUB50012',
      programId: 'DED',
      subjectCode: 'DUB50012',
      subjectName: 'DIGITAL ENTERPRISE'),
  SubjectCourse(
      subjectId: 'DED_DUB51052',
      programId: 'DED',
      subjectCode: 'DUB51052',
      subjectName: 'DIGITAL ENTERPRISE'),
  SubjectCourse(
      subjectId: 'DED_DUE10000',
      programId: 'DED',
      subjectCode: 'DUE10000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DED_DUE10092',
      programId: 'DED',
      subjectCode: 'DUE10092',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DED_DUE20000',
      programId: 'DED',
      subjectCode: 'DUE20000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DED_DUE20082',
      programId: 'DED',
      subjectCode: 'DUE20082',
      subjectName: 'ENGLISH FOR CAREER DEVELOPMENT'),
  SubjectCourse(
      subjectId: 'DED_DUE40000',
      programId: 'DED',
      subjectCode: 'DUE40000',
      subjectName: 'ENGLISH FOR CAREER DEVELOPMENT'),
  SubjectCourse(
      subjectId: 'DED_DUM_30183',
      programId: 'DED',
      subjectCode: 'DUM 30183',
      subjectName: 'MATHEMATICS FOR ELECTRICAL ENGINEERING'),
  SubjectCourse(
      subjectId: 'DED_DUM10122',
      programId: 'DED',
      subjectCode: 'DUM10122',
      subjectName: 'ENGINEERING MATHEMATICS 1'),
  SubjectCourse(
      subjectId: 'DED_DUM20132',
      programId: 'DED',
      subjectCode: 'DUM20132',
      subjectName: 'ENGINEERING MATHEMATICS 2'),
  SubjectCourse(
      subjectId: 'DED_DUS10062',
      programId: 'DED',
      subjectCode: 'DUS10062',
      subjectName: 'PENGHATAN AKIDAH'),
  SubjectCourse(
      subjectId: 'DED_DUS30052',
      programId: 'DED',
      subjectCode: 'DUS30052',
      subjectName: 'SYARIAH DAN KEHIDUPAN'),
  SubjectCourse(
      subjectId: 'DEK_DFK10313',
      programId: 'DEK',
      subjectCode: 'DFK10313',
      subjectName: 'Electrical Circuit Analysis'),
  SubjectCourse(
      subjectId: 'DEK_DFK10323',
      programId: 'DEK',
      subjectCode: 'DFK10323',
      subjectName: 'Analog Circuit Application'),
  SubjectCourse(
      subjectId: 'DEK_DFK10333',
      programId: 'DEK',
      subjectCode: 'DFK10333',
      subjectName: 'Engineering Science For Elektronics'),
  SubjectCourse(
      subjectId: 'DEK_DFK10343',
      programId: 'DEK',
      subjectCode: 'DFK10343',
      subjectName: 'Semiconductor Physics'),
  SubjectCourse(
      subjectId: 'DEK_DFK20312',
      programId: 'DEK',
      subjectCode: 'DFK20312',
      subjectName: 'Electronic CAD'),
  SubjectCourse(
      subjectId: 'DEK_DFK20324',
      programId: 'DEK',
      subjectCode: 'DFK20324',
      subjectName: 'Computer Programming'),
  SubjectCourse(
      subjectId: 'DEK_DFK20334',
      programId: 'DEK',
      subjectCode: 'DFK20334',
      subjectName: 'Digital Electronics'),
  SubjectCourse(
      subjectId: 'DEK_DFK20343',
      programId: 'DEK',
      subjectCode: 'DFK20343',
      subjectName: 'Semiconductor Technology'),
  SubjectCourse(
      subjectId: 'DEK_DFK30323',
      programId: 'DEK',
      subjectCode: 'DFK30323',
      subjectName: 'Electrical Electronics Wiring And Installation'),
  SubjectCourse(
      subjectId: 'DEK_DFK30333',
      programId: 'DEK',
      subjectCode: 'DFK30333',
      subjectName: 'Pneumatic and Electropneumatic Technology'),
  SubjectCourse(
      subjectId: 'DEK_DFK30344',
      programId: 'DEK',
      subjectCode: 'DFK30344',
      subjectName: 'Electronics Packaging'),
  SubjectCourse(
      subjectId: 'DEK_DFK31314',
      programId: 'DEK',
      subjectCode: 'DFK31314',
      subjectName: 'Microcontroller & Interfacing'),
  SubjectCourse(
      subjectId: 'DEK_DFK40314',
      programId: 'DEK',
      subjectCode: 'DFK40314',
      subjectName: 'Signal & Systems'),
  SubjectCourse(
      subjectId: 'DEK_DFK40324',
      programId: 'DEK',
      subjectCode: 'DFK40324',
      subjectName: 'AUTOMATED MANUFACTURING AND MAINTENANCE'),
  SubjectCourse(
      subjectId: 'DEK_DFK40333',
      programId: 'DEK',
      subjectCode: 'DFK40333',
      subjectName: 'ELECTRONICS PRODUCT TESTING'),
  SubjectCourse(
      subjectId: 'DEK_DFK40342',
      programId: 'DEK',
      subjectCode: 'DFK40342',
      subjectName: 'Project proposal'),
  SubjectCourse(
      subjectId: 'DEK_DFK40353',
      programId: 'DEK',
      subjectCode: 'DFK40353',
      subjectName: 'Engineering Statistics'),
  SubjectCourse(
      subjectId: 'DEK_DFK50314',
      programId: 'DEK',
      subjectCode: 'DFK50314',
      subjectName: 'ELECTRONIC AUTOMATION LABORATORY'),
  SubjectCourse(
      subjectId: 'DEK_DFK50323',
      programId: 'DEK',
      subjectCode: 'DFK50323',
      subjectName: 'QUALITY ASSURANCE & QUALITY CONTROL'),
  SubjectCourse(
      subjectId: 'DEK_DFK50333',
      programId: 'DEK',
      subjectCode: 'DFK50333',
      subjectName: 'Fiber Optic Fundamental'),
  SubjectCourse(
      subjectId: 'DEK_DFK50344',
      programId: 'DEK',
      subjectCode: 'DFK50344',
      subjectName: 'Final Year Project'),
  SubjectCourse(
      subjectId: 'DEK_NUE10052',
      programId: 'DEK',
      subjectCode: 'NUE10052',
      subjectName: 'COMMUNICATIVE ENGLISH 1'),
  SubjectCourse(
      subjectId: 'DEK_NUE30041',
      programId: 'DEK',
      subjectCode: 'NUE30041',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'DEK_NUE40000',
      programId: 'DEK',
      subjectCode: 'NUE40000',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'DEK_NUK20032',
      programId: 'DEK',
      subjectCode: 'NUK20032',
      subjectName: 'DIGITAL ENTREPRENEURSHIP'),
  SubjectCourse(
      subjectId: 'DEK_NUS10000',
      programId: 'DEK',
      subjectCode: 'NUS10000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DEK_NUS10032',
      programId: 'DEK',
      subjectCode: 'NUS10032',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DEK_NUS20000',
      programId: 'DEK',
      subjectCode: 'NUS20000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DEK_NUS30000',
      programId: 'DEK',
      subjectCode: 'NUS30000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DEK_NUS40000',
      programId: 'DEK',
      subjectCode: 'NUS40000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'DGS_DKV10213',
      programId: 'DGS',
      subjectCode: 'DKV10213',
      subjectName: 'ENGINEERING SCIENCE'),
  SubjectCourse(
      subjectId: 'DGS_DKV20243',
      programId: 'DGS',
      subjectCode: 'DKV20243',
      subjectName: 'ENGINEERING MATERIALS'),
  SubjectCourse(
      subjectId: 'DGS_DKV40292',
      programId: 'DGS',
      subjectCode: 'DKV40292',
      subjectName: 'PROJECT MANAGEMENT'),
  SubjectCourse(
      subjectId: 'DGS_DPG10214',
      programId: 'DGS',
      subjectCode: 'DPG10214',
      subjectName: 'INTRODUCTION TO GAS PIPING WORKSHOP'),
  SubjectCourse(
      subjectId: 'DGS_DPG10222',
      programId: 'DGS',
      subjectCode: 'DPG10222',
      subjectName: 'INTRODUCTION TO GAS INDUSTRY'),
  SubjectCourse(
      subjectId: 'DGS_DPG10232',
      programId: 'DGS',
      subjectCode: 'DPG10232',
      subjectName: 'FUNDAMENTAL OF PIPE DRAFTING'),
  SubjectCourse(
      subjectId: 'DGS_DPG20244',
      programId: 'DGS',
      subjectCode: 'DPG20244',
      subjectName: 'WELDING TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'DGS_DPG20253',
      programId: 'DGS',
      subjectCode: 'DPG20253',
      subjectName: 'ACTS, REGULATIONS AND STANDARD CODES'),
  SubjectCourse(
      subjectId: 'DGS_DPG21263',
      programId: 'DGS',
      subjectCode: 'DPG21263',
      subjectName: 'FLUID MECHANICS'),
  SubjectCourse(
      subjectId: 'DGS_DPG30283',
      programId: 'DGS',
      subjectCode: 'DPG30283',
      subjectName: 'GAS DISTRIBUTION SYSTEM'),
  SubjectCourse(
      subjectId: 'DGS_DPG30293',
      programId: 'DGS',
      subjectCode: 'DPG30293',
      subjectName: 'GAS STORAGE SYSTEM'),
  SubjectCourse(
      subjectId: 'DGS_DPG30302',
      programId: 'DGS',
      subjectCode: 'DPG30302',
      subjectName: 'ELECTRICAL AND ELECTRONIC FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'DGS_DPG30313',
      programId: 'DGS',
      subjectCode: 'DPG30313',
      subjectName: 'THERMODYNAMICS'),
  SubjectCourse(
      subjectId: 'DGS_DPG31274',
      programId: 'DGS',
      subjectCode: 'DPG31274',
      subjectName: 'PIPING DRAFTING AND INSTRUMENTATION'),
  SubjectCourse(
      subjectId: 'DGS_DPG40323',
      programId: 'DGS',
      subjectCode: 'DPG40323',
      subjectName: 'GAS FLOW MEASUREMENT AND REGULATING SYSTEM'),
  SubjectCourse(
      subjectId: 'DGS_DPG40333',
      programId: 'DGS',
      subjectCode: 'DPG40333',
      subjectName: 'FUEL AND COMBUSTION TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'DGS_DPG40343',
      programId: 'DGS',
      subjectCode: 'DPG40343',
      subjectName: 'CONSTRUCTION WORKS'),
  SubjectCourse(
      subjectId: 'DGS_DPG40354',
      programId: 'DGS',
      subjectCode: 'DPG40354',
      subjectName: 'GAS RETICULATION SYSTEM'),
  SubjectCourse(
      subjectId: 'DGS_DUA20062',
      programId: 'DGS',
      subjectCode: 'DUA20062',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'DGS_DUB40072',
      programId: 'DGS',
      subjectCode: 'DUB40072',
      subjectName: 'START- UP ENTERPRISE'),
  SubjectCourse(
      subjectId: 'DGS_DUE10000',
      programId: 'DGS',
      subjectCode: 'DUE10000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DGS_DUE10092',
      programId: 'DGS',
      subjectCode: 'DUE10092',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DGS_DUE20000',
      programId: 'DGS',
      subjectCode: 'DUE20000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DGS_DUE40000',
      programId: 'DGS',
      subjectCode: 'DUE40000',
      subjectName: 'ENGLISH FOR CAREER DEVELOPMENT'),
  SubjectCourse(
      subjectId: 'DGS_DUM10122',
      programId: 'DGS',
      subjectCode: 'DUM10122',
      subjectName: 'ENGINEERING MATHEMATICS 1'),
  SubjectCourse(
      subjectId: 'DGS_DUM20132',
      programId: 'DGS',
      subjectCode: 'DUM20132',
      subjectName: 'ENGINEERING MATHEMATICS 2'),
  SubjectCourse(
      subjectId: 'DGS_DUN10082',
      programId: 'DGS',
      subjectCode: 'DUN10082',
      subjectName: 'ASAS PENGAJIAN MORAL'),
  SubjectCourse(
      subjectId: 'DGS_DUS10062',
      programId: 'DGS',
      subjectCode: 'DUS10062',
      subjectName: 'PENGHATAN AKIDAH'),
  SubjectCourse(
      subjectId: 'DGS_DUS30052',
      programId: 'DGS',
      subjectCode: 'DUS30052',
      subjectName: 'SYARIAH DAN KEHIDUPAN'),
  SubjectCourse(
      subjectId: 'DPP_DKV10213',
      programId: 'DPP',
      subjectCode: 'DKV10213',
      subjectName: 'ENGINEERING SCIENCE'),
  SubjectCourse(
      subjectId: 'DPP_DKV10222',
      programId: 'DPP',
      subjectCode: 'DKV10222',
      subjectName: 'OCCUPATIONAL SAFETY AND HEALTH'),
  SubjectCourse(
      subjectId: 'DPP_DKV10232',
      programId: 'DPP',
      subjectCode: 'DKV10232',
      subjectName: 'ENGINEERING DRAWING'),
  SubjectCourse(
      subjectId: 'DPP_DKV40292',
      programId: 'DPP',
      subjectCode: 'DKV40292',
      subjectName: 'PROJECT MANAGEMENT'),
  SubjectCourse(
      subjectId: 'DPP_DSA10013',
      programId: 'DPP',
      subjectCode: 'DSA10013',
      subjectName: 'REFRIGERATION AND AIR CONDITIONING FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'DPP_DSA10022',
      programId: 'DPP',
      subjectCode: 'DSA10022',
      subjectName: 'BASIC ELECTRICITY'),
  SubjectCourse(
      subjectId: 'DPP_DSA10032',
      programId: 'DPP',
      subjectCode: 'DSA10032',
      subjectName: 'FABRICATION AND FITTING'),
  SubjectCourse(
      subjectId: 'DPP_DSA20052',
      programId: 'DPP',
      subjectCode: 'DSA20052',
      subjectName: 'ELECTRICAL FOR REFRIGERATION AND AIR CONDITIONING SYSTEM'),
  SubjectCourse(
      subjectId: 'DPP_DSA20062',
      programId: 'DPP',
      subjectCode: 'DSA20062',
      subjectName: 'REFRIGERANT LEGAL REQUIREMENTS'),
  SubjectCourse(
      subjectId: 'DPP_DSA21043',
      programId: 'DPP',
      subjectCode: 'DSA21043',
      subjectName: 'REFRIGERATION AND AIR CONDITIONING MAINTENANCE'),
  SubjectCourse(
      subjectId: 'DPP_DSA30073',
      programId: 'DPP',
      subjectCode: 'DSA30073',
      subjectName: 'INDUSTRIAL REFRIGERATION SYSTEM'),
  SubjectCourse(
      subjectId: 'DPP_DSA30102',
      programId: 'DPP',
      subjectCode: 'DSA30102',
      subjectName: 'VEHICLE AIR CONDITIONING SYSTEM'),
  SubjectCourse(
      subjectId: 'DPP_DSA30113',
      programId: 'DPP',
      subjectCode: 'DSA30113',
      subjectName: 'HVAC-THERMODYNAMICS'),
  SubjectCourse(
      subjectId: 'DPP_DSA31083',
      programId: 'DPP',
      subjectCode: 'DSA31083',
      subjectName: 'RESIDENTIAL AIR CONDITIONING SYSTEM'),
  SubjectCourse(
      subjectId: 'DPP_DSA31093',
      programId: 'DPP',
      subjectCode: 'DSA31093',
      subjectName: 'REFRIGERATION AND AIR CONDITIONING MOTOR CONTROL'),
  SubjectCourse(
      subjectId: 'DPP_DSA40123',
      programId: 'DPP',
      subjectCode: 'DSA40123',
      subjectName: 'REFRIGERATION LOAD ESTIMATION AND EQUIPMENT SELECTION'),
  SubjectCourse(
      subjectId: 'DPP_DSA40133',
      programId: 'DPP',
      subjectCode: 'DSA40133',
      subjectName: 'AIR CONDITIONING LOAD ESTIMATION AND EQUIPMENT SELECTION'),
  SubjectCourse(
      subjectId: 'DPP_DSA40162',
      programId: 'DPP',
      subjectCode: 'DSA40162',
      subjectName: 'PROJECT PROPOSAL'),
  SubjectCourse(
      subjectId: 'DPP_DSA41143',
      programId: 'DPP',
      subjectCode: 'DSA41143',
      subjectName: 'COMMERCIAL AIR CONDITIONING SYSTEM'),
  SubjectCourse(
      subjectId: 'DPP_DSA41153',
      programId: 'DPP',
      subjectCode: 'DSA41153',
      subjectName: 'HEAT TRANSFER'),
  SubjectCourse(
      subjectId: 'DPP_DSA50192',
      programId: 'DPP',
      subjectCode: 'DSA50192',
      subjectName: 'ELECTRONIC FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'DPP_DUA20062',
      programId: 'DPP',
      subjectCode: 'DUA20062',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'DPP_DUB40072',
      programId: 'DPP',
      subjectCode: 'DUB40072',
      subjectName: 'START- UP ENTERPRISE'),
  SubjectCourse(
      subjectId: 'DPP_DUE10000',
      programId: 'DPP',
      subjectCode: 'DUE10000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DPP_DUE10092',
      programId: 'DPP',
      subjectCode: 'DUE10092',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DPP_DUE20000',
      programId: 'DPP',
      subjectCode: 'DUE20000',
      subjectName: 'ENGLISH FOR COMMUNICATIONS 1'),
  SubjectCourse(
      subjectId: 'DPP_DUE40000',
      programId: 'DPP',
      subjectCode: 'DUE40000',
      subjectName: 'ENGLISH FOR CAREER DEVELOPMENT'),
  SubjectCourse(
      subjectId: 'DPP_DUM_20132',
      programId: 'DPP',
      subjectCode: 'DUM 20132',
      subjectName: 'ENGINEERING MATHEMATICS 2'),
  SubjectCourse(
      subjectId: 'DPP_DUM_30172',
      programId: 'DPP',
      subjectCode: 'DUM 30172',
      subjectName: 'MATHEMATICS FOR MECHANICAL ENGINEERING'),
  SubjectCourse(
      subjectId: 'DPP_DUM10122',
      programId: 'DPP',
      subjectCode: 'DUM10122',
      subjectName: 'ENGINEERING MATHEMATICS 1'),
  SubjectCourse(
      subjectId: 'DPP_DUS10062',
      programId: 'DPP',
      subjectCode: 'DUS10062',
      subjectName: 'PENGHATAN AKIDAH'),
  SubjectCourse(
      subjectId: 'DPP_DUS30052',
      programId: 'DPP',
      subjectCode: 'DUS30052',
      subjectName: 'SYARIAH DAN KEHIDUPAN'),
  SubjectCourse(
      subjectId: 'IMF_IMF10013',
      programId: 'IMF',
      subjectCode: 'IMF10013',
      subjectName: 'PRINCIPLES OF ELECTROPLATING'),
  SubjectCourse(
      subjectId: 'IMF_IMF10022',
      programId: 'IMF',
      subjectCode: 'IMF10022',
      subjectName: 'ELECTROPLATING PLANT'),
  SubjectCourse(
      subjectId: 'IMF_IMF10032',
      programId: 'IMF',
      subjectCode: 'IMF10032',
      subjectName: 'WORKSHOP PRACTICE'),
  SubjectCourse(
      subjectId: 'IMF_IMF10042',
      programId: 'IMF',
      subjectCode: 'IMF10042',
      subjectName: 'ENGINEERING MATERIAL'),
  SubjectCourse(
      subjectId: 'IMF_IMF20053',
      programId: 'IMF',
      subjectCode: 'IMF20053',
      subjectName: 'ELECTROPLATING TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'IMF_IMF20063',
      programId: 'IMF',
      subjectCode: 'IMF20063',
      subjectName: 'CHEMICAL FINISHES'),
  SubjectCourse(
      subjectId: 'IMF_IMF20073',
      programId: 'IMF',
      subjectCode: 'IMF20073',
      subjectName: 'PLATING BATH CONTROL'),
  SubjectCourse(
      subjectId: 'IMF_IMF20082',
      programId: 'IMF',
      subjectCode: 'IMF20082',
      subjectName: 'ELECTRICAL TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'IMF_IMF30094',
      programId: 'IMF',
      subjectCode: 'IMF30094',
      subjectName: 'SPECIAL PLATING'),
  SubjectCourse(
      subjectId: 'IMF_IMF30104',
      programId: 'IMF',
      subjectCode: 'IMF30104',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'IMF_IMF30113',
      programId: 'IMF',
      subjectCode: 'IMF30113',
      subjectName: 'COATING TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'IMF_IMF30123',
      programId: 'IMF',
      subjectCode: 'IMF30123',
      subjectName: 'MATERIAL TESTING'),
  SubjectCourse(
      subjectId: 'IMF_IMF30132',
      programId: 'IMF',
      subjectCode: 'IMF30132',
      subjectName: 'WASTE WATER TREATMENT'),
  SubjectCourse(
      subjectId: 'IMF_IMF30141',
      programId: 'IMF',
      subjectCode: 'IMF30141',
      subjectName: 'PRECIOUS METAL PLATING'),
  SubjectCourse(
      subjectId: 'IMF_IMF30152',
      programId: 'IMF',
      subjectCode: 'IMF30152',
      subjectName: 'SAFETY IN CHEMICAL HANDLING'),
  SubjectCourse(
      subjectId: 'IMF_IMF30162',
      programId: 'IMF',
      subjectCode: 'IMF30162',
      subjectName: 'PROJECT MANAGEMENT'),
  SubjectCourse(
      subjectId: 'IMF_NUE10072',
      programId: 'IMF',
      subjectCode: 'NUE10072',
      subjectName: 'NUE10072 ENGLISH FOR WORK'),
  SubjectCourse(
      subjectId: 'IMF_NUK20032',
      programId: 'IMF',
      subjectCode: 'NUK20032',
      subjectName: 'DIGITAL ENTREPRENEURSHIP'),
  SubjectCourse(
      subjectId: 'IMF_NUM10252',
      programId: 'IMF',
      subjectCode: 'NUM10252',
      subjectName: 'MATHEMATICS FOR MECHANICAL'),
  SubjectCourse(
      subjectId: 'IMF_NUS10061',
      programId: 'IMF',
      subjectCode: 'NUS10061',
      subjectName: 'ISLAM DALAM KEHIDUPAN'),
  SubjectCourse(
      subjectId: 'ITW_DUY10091',
      programId: 'ITW',
      subjectCode: 'DUY10091',
      subjectName: 'CO-CURRICULUM 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW10614',
      programId: 'ITW',
      subjectCode: 'MMW10614',
      subjectName: 'SHIELDED METAL ARC WELDING 1F&2F'),
  SubjectCourse(
      subjectId: 'ITW_MMW10624',
      programId: 'ITW',
      subjectCode: 'MMW10624',
      subjectName: 'SHIELDED METAL ARC WELDING 3F&4F'),
  SubjectCourse(
      subjectId: 'ITW_MMW10632',
      programId: 'ITW',
      subjectCode: 'MMW10632',
      subjectName: 'GAS METAL ARC WELDING'),
  SubjectCourse(
      subjectId: 'ITW_MMW40724',
      programId: 'ITW',
      subjectCode: 'MMW40724',
      subjectName: 'SHIELDED METAL ARC WELDING 6G'),
  SubjectCourse(
      subjectId: 'ITW_MMW40733',
      programId: 'ITW',
      subjectCode: 'MMW40733',
      subjectName: 'Welding Activity Planning 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW40743',
      programId: 'ITW',
      subjectCode: 'MMW40743',
      subjectName: 'WELDING ACTIVITY PLANNING 2'),
  SubjectCourse(
      subjectId: 'ITW_MMW40752',
      programId: 'ITW',
      subjectCode: 'MMW40752',
      subjectName: 'Robotic Welding'),
  SubjectCourse(
      subjectId: 'ITW_MMW40762',
      programId: 'ITW',
      subjectCode: 'MMW40762',
      subjectName: 'BASIC AUTOCAD'),
  SubjectCourse(
      subjectId: 'ITW_MMW50413',
      programId: 'ITW',
      subjectCode: 'MMW50413',
      subjectName: 'WELDING ACTIVITIES SUPERVISION 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW50423',
      programId: 'ITW',
      subjectCode: 'MMW50423',
      subjectName: 'WELDING ACTIVITIES SUPERVISION 2'),
  SubjectCourse(
      subjectId: 'ITW_MMW50433',
      programId: 'ITW',
      subjectCode: 'MMW50433',
      subjectName: 'Welding Inspection Activities Coordination 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW50442',
      programId: 'ITW',
      subjectCode: 'MMW50442',
      subjectName: 'WELDING SAFETY ACTIVITIES IMPLEMENTATION'),
  SubjectCourse(
      subjectId: 'ITW_MMW50773',
      programId: 'ITW',
      subjectCode: 'MMW50773',
      subjectName: 'WELDING ACTIVITIES SUPERVISION 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW50783',
      programId: 'ITW',
      subjectCode: 'MMW50783',
      subjectName: 'WELDING ACTIVITIES SUPERVISION 2'),
  SubjectCourse(
      subjectId: 'ITW_MMW50793',
      programId: 'ITW',
      subjectCode: 'MMW50793',
      subjectName: 'Welding Inspection Activities Coordination 1'),
  SubjectCourse(
      subjectId: 'ITW_MMW50802',
      programId: 'ITW',
      subjectCode: 'MMW50802',
      subjectName: 'WELDING SAFETY ACTIVITIES IMPLEMENTATION'),
  SubjectCourse(
      subjectId: 'ITW_NUE30031',
      programId: 'ITW',
      subjectCode: 'NUE30031',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'ITW_NUE40000',
      programId: 'ITW',
      subjectCode: 'NUE40000',
      subjectName: 'COMMUNICATIVE ENGLISH 2'),
  SubjectCourse(
      subjectId: 'ITW_NUM10252',
      programId: 'ITW',
      subjectCode: 'NUM10252',
      subjectName: 'MATHEMATICS FOR MECHANICAL'),
  SubjectCourse(
      subjectId: 'ITW_NUN10000',
      programId: 'ITW',
      subjectCode: 'NUN10000',
      subjectName: 'MORAL DAN PENGHAYATAN NILAI MURNI'),
  SubjectCourse(
      subjectId: 'ITW_NUS10000',
      programId: 'ITW',
      subjectCode: 'NUS10000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'ITW_NUS10022',
      programId: 'ITW',
      subjectCode: 'NUS10022',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'ITW_NUS40000',
      programId: 'ITW',
      subjectCode: 'NUS40000',
      subjectName: 'PENGHAYATAN ISLAM'),
  SubjectCourse(
      subjectId: 'SLR_AYV20001',
      programId: 'SLR',
      subjectCode: 'AYV20001',
      subjectName: 'Core Abilities 2'),
  SubjectCourse(
      subjectId: 'SLR_AYV30002',
      programId: 'SLR',
      subjectCode: 'AYV30002',
      subjectName: 'Core Abilities 3'),
  SubjectCourse(
      subjectId: 'SLR_CKV10022',
      programId: 'SLR',
      subjectCode: 'CKV10022',
      subjectName: 'Engineering Science 1'),
  SubjectCourse(
      subjectId: 'SLR_CMD10135',
      programId: 'SLR',
      subjectCode: 'CMD10135',
      subjectName: 'Engineering Drawing'),
  SubjectCourse(
      subjectId: 'SLR_CMD10145',
      programId: 'SLR',
      subjectCode: 'CMD10145',
      subjectName: 'Engineering CADD'),
  SubjectCourse(
      subjectId: 'SLR_CMD10154',
      programId: 'SLR',
      subjectCode: 'CMD10154',
      subjectName: 'Mechanical CADD 1'),
  SubjectCourse(
      subjectId: 'SLR_CMD10172',
      programId: 'SLR',
      subjectCode: 'CMD10172',
      subjectName: 'Mechanical Workshop'),
  SubjectCourse(
      subjectId: 'SLR_CMD20062',
      programId: 'SLR',
      subjectCode: 'CMD20062',
      subjectName: 'M & E Services Drawing 1'),
  SubjectCourse(
      subjectId: 'SLR_CMD21044',
      programId: 'SLR',
      subjectCode: 'CMD21044',
      subjectName: 'Mechanical Draughting 1'),
  SubjectCourse(
      subjectId: 'SLR_CMD21072',
      programId: 'SLR',
      subjectCode: 'CMD21072',
      subjectName: 'Engineering Science 2'),
  SubjectCourse(
      subjectId: 'SLR_CMD30112',
      programId: 'SLR',
      subjectCode: 'CMD30112',
      subjectName: 'Process Piping Draughting'),
  SubjectCourse(
      subjectId: 'SLR_CMD30122',
      programId: 'SLR',
      subjectCode: 'CMD30122',
      subjectName: 'Engineering Material Fundamentals'),
  SubjectCourse(
      subjectId: 'SLR_CMD31084',
      programId: 'SLR',
      subjectCode: 'CMD31084',
      subjectName: 'Mechanical Draughting 2'),
  SubjectCourse(
      subjectId: 'SLR_CMD31094',
      programId: 'SLR',
      subjectCode: 'CMD31094',
      subjectName: 'CAD For Engineering 3'),
  SubjectCourse(
      subjectId: 'SLR_CMD31102',
      programId: 'SLR',
      subjectCode: 'CMD31102',
      subjectName: 'M & E Services Drawing 2'),
  SubjectCourse(
      subjectId: 'SLR_CUA30012',
      programId: 'SLR',
      subjectCode: 'CUA30012',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'SLR_CUE10021',
      programId: 'SLR',
      subjectCode: 'CUE10021',
      subjectName: 'ENGLISH FOR WORKPLACE PREPARATION'),
  SubjectCourse(
      subjectId: 'SLR_CUE21022',
      programId: 'SLR',
      subjectCode: 'CUE21022',
      subjectName: 'ENGLISH AND COMMUNICATIONS 2'),
  SubjectCourse(
      subjectId: 'SLR_CUS10111',
      programId: 'SLR',
      subjectCode: 'CUS10111',
      subjectName: 'JATI DIRI MUSLIM'),
  SubjectCourse(
      subjectId: 'SLR_CUS20061',
      programId: 'SLR',
      subjectCode: 'CUS20061',
      subjectName: 'KEINDAHAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SLR_CUS30071',
      programId: 'SLR',
      subjectCode: 'CUS30071',
      subjectName: 'KESYUMULAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMI_AYV30002',
      programId: 'SMI',
      subjectCode: 'AYV30002',
      subjectName: 'CORE ABILITIES 3'),
  SubjectCourse(
      subjectId: 'SMI_CKV30012',
      programId: 'SMI',
      subjectCode: 'CKV30012',
      subjectName: 'ENGINEERING MATERIALS & PROCESSING'),
  SubjectCourse(
      subjectId: 'SMI_CKV30022',
      programId: 'SMI',
      subjectCode: 'CKV30022',
      subjectName: 'ENGINEERING SCIENCE 1'),
  SubjectCourse(
      subjectId: 'SMI_CSS10032',
      programId: 'SMI',
      subjectCode: 'CSS10032',
      subjectName: 'INDUSTRIAL PNEUMATIC SYSTEM'),
  SubjectCourse(
      subjectId: 'SMI_CSS10132',
      programId: 'SMI',
      subjectCode: 'CSS10132',
      subjectName: 'OCCUPATIONAL SAFETY & HEALTH'),
  SubjectCourse(
      subjectId: 'SMI_CSS10142',
      programId: 'SMI',
      subjectCode: 'CSS10142',
      subjectName: 'ENGINEERING FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'SMI_CSS10153',
      programId: 'SMI',
      subjectCode: 'CSS10153',
      subjectName: 'INDUSTRIAL PNEUMATIC SYSTEM'),
  SubjectCourse(
      subjectId: 'SMI_CSS10164',
      programId: 'SMI',
      subjectCode: 'CSS10164',
      subjectName: 'ELECTRICAL FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'SMI_CSS10174',
      programId: 'SMI',
      subjectCode: 'CSS10174',
      subjectName: 'INDUSTRIAL TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'SMI_CSS10184',
      programId: 'SMI',
      subjectCode: 'CSS10184',
      subjectName: 'INDUSTRIAL MAINTENANCE 1'),
  SubjectCourse(
      subjectId: 'SMI_CSS30103',
      programId: 'SMI',
      subjectCode: 'CSS30103',
      subjectName: 'CNC PROGRAMMING'),
  SubjectCourse(
      subjectId: 'SMI_CSS30113',
      programId: 'SMI',
      subjectCode: 'CSS30113',
      subjectName: 'PROGRAMMABLE LOGIC CONTROL'),
  SubjectCourse(
      subjectId: 'SMI_CSS30123',
      programId: 'SMI',
      subjectCode: 'CSS30123',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'SMI_CSS31093',
      programId: 'SMI',
      subjectCode: 'CSS31093',
      subjectName: 'SERVICE & MAINTENANCE 3'),
  SubjectCourse(
      subjectId: 'SMI_CUA30012',
      programId: 'SMI',
      subjectCode: 'CUA30012',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'SMI_CUE10021',
      programId: 'SMI',
      subjectCode: 'CUE10021',
      subjectName: 'ENGLISH FOR WORKPLACE PREPARATION'),
  SubjectCourse(
      subjectId: 'SMI_CUS10111',
      programId: 'SMI',
      subjectCode: 'CUS10111',
      subjectName: 'JATI DIRI MUSLIM'),
  SubjectCourse(
      subjectId: 'SMI_CUS30071',
      programId: 'SMI',
      subjectCode: 'CUS30071',
      subjectName: 'KESYUMULAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMI_CUY10071',
      programId: 'SMI',
      subjectCode: 'CUY10071',
      subjectName: 'KOKURIKULUM 1'),
  SubjectCourse(
      subjectId: 'SMI_CUY10111',
      programId: 'SMI',
      subjectCode: 'CUY10111',
      subjectName: 'KOKURIKULUM 1'),
  SubjectCourse(
      subjectId: 'SMI_MMW10843',
      programId: 'SMI',
      subjectCode: 'MMW10843',
      subjectName: 'WELDING DOCUMENT PREPARATION'),
  SubjectCourse(
      subjectId: 'SMI_MMW50814',
      programId: 'SMI',
      subjectCode: 'MMW50814',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'SMK_AYV20001',
      programId: 'SMK',
      subjectCode: 'AYV20001',
      subjectName: 'CORE ABILITY'),
  SubjectCourse(
      subjectId: 'SMK_CFM20023',
      programId: 'SMK',
      subjectCode: 'CFM20023',
      subjectName: 'MACHINE TOOLS TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'SMK_CFM20033',
      programId: 'SMK',
      subjectCode: 'CFM20033',
      subjectName: 'HYDRAULIC SYSTEMS TECHNOLOGY'),
  SubjectCourse(
      subjectId: 'SMK_CFM20042',
      programId: 'SMK',
      subjectCode: 'CFM20042',
      subjectName: 'ELECTRONIC FUNDAMENTAL'),
  SubjectCourse(
      subjectId: 'SMK_CFM30054',
      programId: 'SMK',
      subjectCode: 'CFM30054',
      subjectName: 'INTEGRATED SYSTEM'),
  SubjectCourse(
      subjectId: 'SMK_CFM30063',
      programId: 'SMK',
      subjectCode: 'CFM30063',
      subjectName: 'PROGRAMMABLE LOGIC CONTROL'),
  SubjectCourse(
      subjectId: 'SMK_CFM30083',
      programId: 'SMK',
      subjectCode: 'CFM30083',
      subjectName: 'FINAL YEAR PROJECT'),
  SubjectCourse(
      subjectId: 'SMK_CFM32073',
      programId: 'SMK',
      subjectCode: 'CFM32073',
      subjectName: 'MACHINE MAINTENANCE'),
  SubjectCourse(
      subjectId: 'SMK_CFV20132',
      programId: 'SMK',
      subjectCode: 'CFV20132',
      subjectName: 'PNEUMATIC AND ELECTROPNEUMATIC'),
  SubjectCourse(
      subjectId: 'SMK_CFV30122',
      programId: 'SMK',
      subjectCode: 'CFV30122',
      subjectName: 'ELECTRICAL MACHINE TECHNOLOFY'),
  SubjectCourse(
      subjectId: 'SMK_CKV20062',
      programId: 'SMK',
      subjectCode: 'CKV20062',
      subjectName: 'COMPUTER AIDED DRAUGHTING'),
  SubjectCourse(
      subjectId: 'SMK_CUA30012',
      programId: 'SMK',
      subjectCode: 'CUA30012',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'SMK_CUB2_31022',
      programId: 'SMK',
      subjectCode: 'CUB2/31022',
      subjectName: 'E-TECHNOPRENEUR 2'),
  SubjectCourse(
      subjectId: 'SMK_CUE21022',
      programId: 'SMK',
      subjectCode: 'CUE21022',
      subjectName: 'ENGLISH AND COMMUNICATIONS 2'),
  SubjectCourse(
      subjectId: 'SMK_CUM21022',
      programId: 'SMK',
      subjectCode: 'CUM21022',
      subjectName: 'TECHNICAL MATHEMATICS 2'),
  SubjectCourse(
      subjectId: 'SMK_CUS20061',
      programId: 'SMK',
      subjectCode: 'CUS20061',
      subjectName: 'KEINDAHAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMK_CUS30071',
      programId: 'SMK',
      subjectCode: 'CUS30071',
      subjectName: 'KESYUMULAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMK_CUY21021',
      programId: 'SMK',
      subjectCode: 'CUY21021',
      subjectName: 'CO - CURICULUM'),
  SubjectCourse(
      subjectId: 'SMM_AYV30001',
      programId: 'SMM',
      subjectCode: 'AYV30001',
      subjectName: 'Core Ability 2'),
  SubjectCourse(
      subjectId: 'SMM_AYV30002',
      programId: 'SMM',
      subjectCode: 'AYV30002',
      subjectName: 'Core Ability 3'),
  SubjectCourse(
      subjectId: 'SMM_CKV20022',
      programId: 'SMM',
      subjectCode: 'CKV20022',
      subjectName: 'Engineering Science 1'),
  SubjectCourse(
      subjectId: 'SMM_CUA30012',
      programId: 'SMM',
      subjectCode: 'CUA30012',
      subjectName: 'PENGAJIAN MALAYSIA'),
  SubjectCourse(
      subjectId: 'SMM_CUB20012',
      programId: 'SMM',
      subjectCode: 'CUB20012',
      subjectName: 'E-TECHNOPRENEUR 1'),
  SubjectCourse(
      subjectId: 'SMM_CUE10021',
      programId: 'SMM',
      subjectCode: 'CUE10021',
      subjectName: 'ENGLISH FOR WORKPLACE PREPARATION'),
  SubjectCourse(
      subjectId: 'SMM_CUE21022',
      programId: 'SMM',
      subjectCode: 'CUE21022',
      subjectName: 'ENGLISH AND COMMUNICATIONS 2'),
  SubjectCourse(
      subjectId: 'SMM_CUM21022',
      programId: 'SMM',
      subjectCode: 'CUM21022',
      subjectName: 'TECHNICAL MATHEMATICS 2'),
  SubjectCourse(
      subjectId: 'SMM_CUS10111',
      programId: 'SMM',
      subjectCode: 'CUS10111',
      subjectName: 'JATI DIRI MUSLIM'),
  SubjectCourse(
      subjectId: 'SMM_CUS20061',
      programId: 'SMM',
      subjectCode: 'CUS20061',
      subjectName: 'KEINDAHAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMM_CUS30071',
      programId: 'SMM',
      subjectCode: 'CUS30071',
      subjectName: 'KESYUMULAN AD-DEEN'),
  SubjectCourse(
      subjectId: 'SMM_CUY10071',
      programId: 'SMM',
      subjectCode: 'CUY10071',
      subjectName: 'KOKURIKULUM 1'),
  SubjectCourse(
      subjectId: 'SMM_CVM10175',
      programId: 'SMM',
      subjectCode: 'CVM10175',
      subjectName: 'Engine Technology'),
  SubjectCourse(
      subjectId: 'SMM_CVM10184',
      programId: 'SMM',
      subjectCode: 'CVM10184',
      subjectName: 'Electrical and End Electronic'),
  SubjectCourse(
      subjectId: 'SMM_CVM10194',
      programId: 'SMM',
      subjectCode: 'CVM10194',
      subjectName: 'Workshop Technology'),
  SubjectCourse(
      subjectId: 'SMM_CVM10202',
      programId: 'SMM',
      subjectCode: 'CVM10202',
      subjectName: 'Basic Ship Contruction'),
  SubjectCourse(
      subjectId: 'SMM_CVM10212',
      programId: 'SMM',
      subjectCode: 'CVM10212',
      subjectName: 'Engineering Drawing'),
  SubjectCourse(
      subjectId: 'SMM_CVM20063',
      programId: 'SMM',
      subjectCode: 'CVM20063',
      subjectName: 'Marine Diesel Engine 1'),
  SubjectCourse(
      subjectId: 'SMM_CVM20073',
      programId: 'SMM',
      subjectCode: 'CVM20073',
      subjectName: 'Electrical and Electronic System for High Speed Engine'),
  SubjectCourse(
      subjectId: 'SMM_CVM20082',
      programId: 'SMM',
      subjectCode: 'CVM20082',
      subjectName: 'Marine Refrigeration and Air-Conditioning'),
  SubjectCourse(
      subjectId: 'SMM_CVM20092',
      programId: 'SMM',
      subjectCode: 'CVM20092',
      subjectName: 'Hydraulic and Pneumatic System'),
  SubjectCourse(
      subjectId: 'SMM_CVM30112',
      programId: 'SMM',
      subjectCode: 'CVM30112',
      subjectName: 'Shipboard Electrical System'),
  SubjectCourse(
      subjectId: 'SMM_CVM30122',
      programId: 'SMM',
      subjectCode: 'CVM30122',
      subjectName: 'Marine Workshop Practice'),
  SubjectCourse(
      subjectId: 'SMM_CVM30132',
      programId: 'SMM',
      subjectCode: 'CVM30132',
      subjectName: 'Marine Engineering Practice'),
  SubjectCourse(
      subjectId: 'SMM_CVM30142',
      programId: 'SMM',
      subjectCode: 'CVM30142',
      subjectName: 'Marine Auxiliary Boiler and Turbine'),
  SubjectCourse(
      subjectId: 'SMM_CVM30152',
      programId: 'SMM',
      subjectCode: 'CVM30152',
      subjectName: 'Marine Auxiliary Machinery'),
  SubjectCourse(
      subjectId: 'SMM_CVM30162',
      programId: 'SMM',
      subjectCode: 'CVM30162',
      subjectName: 'Administrative Functions'),
  SubjectCourse(
      subjectId: 'SMM_CVM31103',
      programId: 'SMM',
      subjectCode: 'CVM31103',
      subjectName: 'Marine Diesel Engine 2'),
];
