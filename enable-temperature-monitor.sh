#!/bin/bash

# Install Sensor package
apt-get install lm-sensors


# Add Sensors information to the pm package
if ! grep -q "thermalstate" /usr/share/perl5/PVE/API2/Nodes.pm; then
  sed -i "s/\tmy \$dinfo = df('\/', 1);     # output is bytes/\t\$res->{thermalstate} = JSON->new->utf8->decode(\`sensors-format\`);\n\n&/g" /usr/share/perl5/PVE/API2/Nodes.pm 
fi

# Update the UI to display the data
line=`grep -n "bodyPadding: '15 5 15 5'," /usr/share/pve-manager/js/pvemanagerlib.js | cut -d ':' -f1`;
if [ ! -z "${line}" ]; then
  lineBefore=$(expr "$line" - "1")
  sed -i "s/bodyPadding: '15 5 15 5',/bodyPadding: '15 20 15 20',/g" /usr/share/pve-manager/js/pvemanagerlib.js
  sed -i "${lineBefore}s/height: 300/height: 360/g" /usr/share/pve-manager/js/pvemanagerlib.js

  line=`grep -n "textField: 'pveversion'," /usr/share/pve-manager/js/pvemanagerlib.js | cut -d ':' -f1`;
  endLine=$(expr "$line" + "5")

  functionData="function(value){\n              if (value) {\n                var values = Object.values(value);\n                var sum = values.map((entry) => {\n                  var decimalMatches = entry.match(/(\\d+)/);\n                  if (decimalMatches) {\n                    return Number.parseFloat(decimalMatches[0]);\n                  }\n\n                  return null;\n                }).filter((entry) => !Number.isNaN(entry))\n                .reduce((value1, value2) => value1 + value2);\n                var average = sum / values.length;\n                return \"Average: \" + average + \" C\";\n              } else {\n                return \"Not Available\";\n              }";
  additionalEntry=",\n        {\n            itemId: 'thermal',\n            colspan: 2,\n            printBar: false,\n            title: gettext('CPU Thermal State'),\n            textField: 'thermalstate',\n            renderer:${functionData},\n            },\n        }"
  sed -i "${line},${endLine}s@}@}${additionalEntry}@g" /usr/share/pve-manager/js/pvemanagerlib.js
fi

# Add the CPU Temperature to the external metrics
if ! grep -q "sensors-format" /usr/share/perl5/PVE/Service/pvestatd.pm; then
  additionalEntry="my \$cpuTemps = JSON->new->utf8->decode(\`sensors-format\`);\n    my \$thermalinfo = ( );\n    foreach my \$cpuName (keys %\$cpuTemps) {\n      \$thermalinfo->{\$cpuName}->{'temperature'} = \$cpuTemps->{\$cpuName};\n    }\n\n    &";
  sed -i "s/my \$dinfo = df('\/', 1);     # output is bytes/${additionalEntry}/g" /usr/share/perl5/PVE/Service/pvestatd.pm
  sed -i 's/nics => \$netdev,/nics => \$netdev,\n\tcpu_temperature => \$thermalinfo,/g' /usr/share/perl5/PVE/Service/pvestatd.pm
fi

systemctl restart pvestatd
systemctl restart pveproxy
