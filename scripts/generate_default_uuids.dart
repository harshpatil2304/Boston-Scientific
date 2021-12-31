import 'dart:io';

// source: https://www.bluetooth.com/specifications/assigned-numbers/

Future<int> main() async {
  final dir = File(Platform.script.toFilePath()).parent;
  final servicesFile = File(dir.path + "/services_uuids.csv");
  final characteristicsFile = File(dir.path + "/characteristics_uuids.csv");
  final outputFile = File(dir.path + "/output.dart");

  if (await outputFile.exists()) {
    stderr.writeln("Output file already exists!");
    stderr.write("Overwrite? (Y/n)");
    final line = stdin.readLineSync();
    if (line?.toLowerCase() == "n") {
      exit(3);
    }
    await outputFile.delete();
  }

  const outputFileHeader =
      "/// This file has been automatically generated by the script\n"
      "/// scripts/generate_default_uuids.dart. If you need more uuids please change\n"
      "/// the csv files and regenerate the file.\n"
      "\n"
      "// ignore_for_file: constant_identifier_names\n"
      "\n"
      "part of flutter_web_bluetooth;\n"
      "\n"
      "/// A generated class for holding default characteristics/ services.\n"
      "abstract class BluetoothDefaultUUIDS {\n"
      "    /// The name of the service/ characteristic\n"
      "    final String name;\n"
      "    /// The shorter 16 bit uuid of the service/ characteristic.\n"
      "    final String uuid16;\n"
      "    /// The full uuid of the service/ characteristic.\n"
      "    final String uuid;\n"
      "    /// The ordinal (place in the list)\n"
      "    final int ordinal;\n"
      "\n"
      "    /// The constructor for a new default characteristic or service.\n"
      "    const BluetoothDefaultUUIDS._(this.name, this.uuid16, this.uuid, this.ordinal);\n"
      "}\n\n";

  var servicesUuidClass =
      "/// All the default Bluetooth low energy services are statically defined in this class.\n"
      "/// See: [values] for a list of all the services.\n"
      "class BluetoothDefaultServiceUUIDS extends BluetoothDefaultUUIDS {\n"
      "\n"
      "    const BluetoothDefaultServiceUUIDS._(String name, String uuid16, String uuid, int ordinal): super._(name, uuid16, uuid, ordinal);\n"
      "\n";

  var serviceUuidValuesLower = "[\n";
  var servicesUuidValuesUpper = "[\n";
  await readThroughFile(servicesFile, (holder) {
    servicesUuidClass += "    /// The default service for ${holder.name}\n"
        "    static const ${holder.variableNameLower} = BluetoothDefaultServiceUUIDS._('${holder.name}', "
        "'${holder.uuid16}', "
        "'${holder.uuid}', "
        "${holder.ordinal});\n"
        "    /// This is deprecated use [${holder.variableNameLower}] instead.\n"
        "    static const ${holder.variableNameUpper} = ${holder.variableNameLower};\n";
    serviceUuidValuesLower += "        ${holder.variableNameLower},\n";
    servicesUuidValuesUpper += "        ${holder.variableNameUpper},\n";
  });

  serviceUuidValuesLower += "    ];\n";
  servicesUuidValuesUpper += "    ];\n";
  servicesUuidClass +=
      "\n\n    /// All the default services.\n    static const values = $serviceUuidValuesLower";
  servicesUuidClass +=
      "\n    /// All the default services. Deprecated use [values] instead.\n    static const VALUES = $servicesUuidValuesUpper";
  servicesUuidClass += "}\n\n";

  var characteristicUuidClass =
      "/// All the default Bluetooth low energy characteristics are statically defined in this class.\n"
      "/// See: [values] for a list of all the characteristics.\n"
      "class BluetoothDefaultCharacteristicUUIDS extends BluetoothDefaultUUIDS {\n"
      "\n"
      "    const BluetoothDefaultCharacteristicUUIDS._(String name, String uuid16, String uuid, int ordinal): super._(name, uuid16, uuid, ordinal);\n"
      "\n";

  var characteristicUuidValuesUpper = "[\n";
  var characteristicUuidValuesLower = "[\n";
  await readThroughFile(characteristicsFile, (holder) {
    characteristicUuidClass +=
        "    /// The default characteristic for ${holder.name}\n"
        "    static const ${holder.variableNameLower} = BluetoothDefaultCharacteristicUUIDS._('${holder.name}', "
        "'${holder.uuid16}', "
        "'${holder.uuid}', "
        "${holder.ordinal});\n"
        "    /// This is deprecated use [${holder.variableNameLower}] instead.\n"
        "    static const ${holder.variableNameUpper} = ${holder.variableNameLower};\n";
    characteristicUuidValuesLower += "        ${holder.variableNameLower},\n";
    characteristicUuidValuesUpper += "        ${holder.variableNameUpper},\n";
  });

  characteristicUuidValuesUpper += "    ];\n";
  characteristicUuidValuesLower += "    ];\n";
  characteristicUuidClass +=
      "\n\n    /// All the default characteristics.\n    static const values = $characteristicUuidValuesLower"
      "\n    /// All the default characteristics. Deprecated use [values] instead.\n    static const VALUES = $characteristicUuidValuesUpper";
  characteristicUuidClass += "}\n\n";

  await outputFile.create();
  await outputFile.writeAsString(outputFileHeader, mode: FileMode.writeOnly);
  await outputFile.writeAsString(servicesUuidClass,
      mode: FileMode.writeOnlyAppend);
  await outputFile.writeAsString(characteristicUuidClass,
      mode: FileMode.writeOnlyAppend);
  print('Done');
  return 0;
}

Future<void> readThroughFile(
    File inputFile, void Function(CharacteristicHolder holder) forEach) async {
  final lines = await inputFile.readAsLines();
  for (int i = 0; i < lines.length; i++) {
    final columns = lines[i].split(",");
    if (columns.length != 2) {
      stderr.writeln("There should be 2 columns at line ${i + 1}");
      exit(4);
    }
    final uuidInt = int.parse(columns[0].replaceFirst("0x", ""), radix: 16);
    final name = columns[1].replaceAll("\r", "").replaceAll("\n", "").trim();
    final variableNameUpper = name
        .toUpperCase()
        .replaceAll(" ", "_")
        .replaceAll("-", "_")
        .replaceAll(".", "_");
    final variableNameLower = name
        .replaceAll("-", "_")
        .replaceAll(".", "_")
        .toLowerCase()
        .split(" ")
        .reduce((value, element) {
      return value + '${element[0].toUpperCase()}${element.substring(1)}';
    });
    final uuid16 = uuidInt.toRadixString(16).toLowerCase().padLeft(4, '0');
    final uuid =
        '${uuidInt.toRadixString(16).toLowerCase().padLeft(8, '0')}-0000-1000-8000-00805f9b34fb';
    forEach(CharacteristicHolder(
        variableNameUpper, variableNameLower, name, uuid16, uuid, i));
  }
}

class CharacteristicHolder {
  final String variableNameUpper;
  final String variableNameLower;
  final String name;
  final String uuid16;
  final String uuid;
  final int ordinal;

  CharacteristicHolder(this.variableNameUpper, this.variableNameLower,
      this.name, this.uuid16, this.uuid, this.ordinal);
}
