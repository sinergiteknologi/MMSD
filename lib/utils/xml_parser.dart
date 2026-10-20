import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/bisnis_option.dart';
import '../models/code_name.dart';
import '../models/data_pref.dart';
import '../models/report_models.dart';
import '../models/user_model.dart';

class XmlParser {
  static String? _jsonValue(dynamic node, String key) {
    if (node is Map) {
      if (node.containsKey(key) && node[key] != null && node[key] is! Map && node[key] is! List) {
        return node[key].toString();
      }
      for (final value in node.values) {
        final found = _jsonValue(value, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String? parseSoapFault(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final faults = document.descendants.whereType<XmlElement>().where(
        (element) => element.name.local == 'Fault',
      );
      if (faults.isEmpty) return null;
      final fault = faults.first;
      const preferredTags = ['ErrorMessage', 'faultstring', 'faultcode'];
      for (final tagName in preferredTags) {
        final matches = fault.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == tagName,
        );
        if (matches.isNotEmpty && matches.first.innerText.trim().isNotEmpty) {
          return matches.first.innerText.trim();
        }
      }
      return 'SOAP Fault tanpa pesan.';
    } catch (_) {
      return null;
    }
  }

  static String? getTagValue(String xmlString, String tagName) {
    final raw = xmlString.trim();
    if (raw.startsWith('{')) {
      try {
        return _jsonValue(jsonDecode(raw), tagName);
      } catch (_) {
        return null;
      }
    }
    try {
      final document = XmlDocument.parse(xmlString);
      final elements = document.findAllElements(tagName);
      if (elements.isEmpty) return null;
      return elements.first.innerText;
    } catch (_) {
      return null;
    }
  }

  static String tag(String xmlString, String tagName) {
    return getTagValue(xmlString, tagName) ?? '';
  }

  static List<String> parsePipeDelimited(String xmlString, String tagName) {
    final value = getTagValue(xmlString, tagName);
    if (value == null || value.isEmpty) return [];
    return value.split('|');
  }

  static List<CodeName> parseCodeName(String xmlString) {
    final codes = parsePipeDelimited(xmlString, 'Code');
    final names = parsePipeDelimited(xmlString, 'Name');
    final length = codes.length < names.length ? codes.length : names.length;
    return List.generate(
      length,
      (index) => CodeName(code: codes[index], name: names[index]),
    );
  }

  static DataPref parseDataPref(String xmlString, {int maxPref = 55}) {
    final values = <String, String>{};
    for (var i = 1; i <= maxPref; i++) {
      final value = getTagValue(xmlString, 'Pref$i');
      if (value != null) values['Pref$i'] = value;
    }
    return DataPref(values);
  }

  static List<BisnisOption> parseBisnis(String xmlString) {
    final codes = parsePipeDelimited(xmlString, 'Pref1');
    final names = parsePipeDelimited(xmlString, 'Pref2');
    final servers = parsePipeDelimited(xmlString, 'Pref3');
    final length = [
      codes.length,
      names.length,
      servers.length,
    ].reduce((a, b) => a < b ? a : b);
    return List.generate(
      length,
      (index) => BisnisOption(
        code: codes[index],
        name: names[index],
        server: servers[index],
      ),
    );
  }

  static UserModel? parseLogin({
    required String xmlString,
    required String username,
    required String password,
  }) {
    final kodeCabang = tag(xmlString, 'KodeCabang');
    if (kodeCabang.isEmpty) return null;
    return UserModel.fromLoginXml(
      username: username,
      password: password,
      kodeCabang: kodeCabang,
      namaCabang: tag(xmlString, 'NamaCabang'),
      salesCode: tag(xmlString, 'SalesCode'),
      salesName: tag(xmlString, 'SalesName'),
      branchAut: tag(xmlString, 'BranchAut'),
      mobileAut: tag(xmlString, 'MobileAut'),
      userGroup: tag(xmlString, 'UserGroup'),
      userStatus: tag(xmlString, 'UserStatus'),
      branchNameAut: tag(xmlString, 'BranchNameAut'),
    );
  }

  static bool parseStatus(String xmlString) {
    final value = tag(xmlString, 'Status').toLowerCase();
    return value == 'true' || value == '1';
  }

  static String parseVersi(String xmlString) => tag(xmlString, 'Versi');

  static ReportDaily parseReportDaily(String xmlString) {
    final days = <String, String>{};
    for (var i = 1; i <= 31; i++) {
      days['d$i'] = tag(xmlString, 'd$i');
    }
    return ReportDaily(
      busCode: tag(xmlString, 'BusCode'),
      business: tag(xmlString, 'Business'),
      user: tag(xmlString, 'User'),
      status: tag(xmlString, 'Status'),
      days: days,
      total: tag(xmlString, 'dTotal'),
    );
  }

  static ReportActivity parseReportActivity(String xmlString) {
    return ReportActivity(
      activityName: tag(xmlString, 'ActivityName'),
      subActivityName: tag(xmlString, 'SubActivityName'),
      actNumber: tag(xmlString, 'ACTNumber'),
      actName: tag(xmlString, 'ACTName'),
      spvName: tag(xmlString, 'SPVName'),
      salesName: tag(xmlString, 'SalesName'),
      startDate: tag(xmlString, 'StartDate'),
      endDate: tag(xmlString, 'EndDate'),
      cityName: tag(xmlString, 'CityName'),
      districtName: tag(xmlString, 'DistrictName'),
      totalProspect: tag(xmlString, 'TotalProspect'),
      totalSpk: tag(xmlString, 'TotalSPK'),
      totalDo: tag(xmlString, 'TotalDO'),
    );
  }
}
