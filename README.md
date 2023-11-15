# Proxmox Temperature
These scripts are for enabling temperature reporting on Proxmox hosts. This functionality relies on the `lm-sensors` package. The `sensors-format` script simplifies the output of the `sensors -j` command to just `{ "cpu.0": "...", ...}`.

The `enable-temperature-monitor.sh` script performs four operations:
1. Installs the `lm-sensors` package
2. Updates the `/usr/share/perl5/PVE/API2/Nodes.pm` script to return the sensor data in the status request for the API request.
3. Updates the `/usr/share/pve-manager/js/pvemanagerlib.js` file to include a temperature field on the "Summary Page"
![image](https://github.com/jsmithers/proxmox-temperature/assets/9978858/9a499597-0646-4271-981c-517c493eb6b6)
4. Updates the `/usr/share/perl5/PVE/Service/pvestatd.pm` script to add the sensor data to any external metrics reporting.
   * In Telgraf the data can be queried using a query similar to the following.
   * `SELECT mean("temperature") FROM "cpu_temperature" WHERE $timeFilter GROUP BY time($__interval), "instance", "host" fill(linear)`

## How to Install
```bash
curl -O --output-dir /usr/bin https://raw.githubusercontent.com/jsmithers/proxmox-temperature/main/sensors-format && chmod 775 /usr/bin/sensors-format \
 && pushd /tmp && curl -O https://raw.githubusercontent.com/jsmithers/proxmox-temperature/main/enable-temperature-monitor.sh && chmod 775 enable-temperature-monitor.sh \
 && /tmp/enable-temperature-monitor.sh; rm /tmp/enable-temperature-monitor.sh; popd
```

**Notes:**
This work is partially based on [this reddit post](https://www.reddit.com/r/homelab/comments/rhq56e/displaying_cpu_temperature_in_proxmox_summery_in/).
