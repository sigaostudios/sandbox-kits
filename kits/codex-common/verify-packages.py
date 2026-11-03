"""Keep inherited deb/* capabilities truthful when composing a common overlay.

m.8 PackageVersion retains up to three numeric components, omits the epoch
and distro revision, and omits upstream tilde versions. Package removals are
never allowed, including packages without a representable capability version.
"""
from pathlib import Path
import re
import sys
import subprocess


def installed(path):
    packages = {}
    for stanza in Path(path).read_text().split("\n\n"):
        fields = dict(line.split(": ", 1) for line in stanza.splitlines()
                      if ": " in line and not line.startswith((" ", "\t")))
        if fields.get("Status") == "install ok installed":
            packages[fields["Package"]] = fields["Version"]
    return packages


def capability_version(version):
    raw = re.sub(r"^\d+:", "", version)
    if "~" in raw.rsplit("-", 1)[0]:
        return ""
    match = re.match(r"[0-9]+(?:\.[0-9]+){0,2}", raw)
    return match[0] if match else ""


def package_preferences(packages, available):
    records = []
    for line in available.splitlines():
        fields = line.split("|")
        if len(fields) < 2:
            continue
        name, candidate = (field.strip() for field in fields[:2])
        inherited = packages.get(name.split(":", 1)[0])
        if inherited and capability_version(inherited) and capability_version(inherited) != capability_version(candidate):
            records.append(f"Package: {name}\nPin: version {candidate}\nPin-Priority: -1\n")
    return "\n".join(dict.fromkeys(records))


if __name__ == "__main__":
    before = installed("/usr/share/sandbox-kits/dpkg-status.before")
    if sys.argv[1:] == ["--pin-inherited"]:
        available = subprocess.check_output(["apt-cache", "madison", *before], text=True)
        Path("/etc/apt/preferences.d/sandbox-inherited-packages").write_text(package_preferences(before, available))
        raise SystemExit(0)
    after = installed("/var/lib/dpkg/status")
    for name, version in before.items():
        if name not in after:
            raise SystemExit("Common mixin removed upstream package: " + name)
        expected = capability_version(version)
        if expected and expected != capability_version(after[name]):
            raise SystemExit("Common mixin changed inherited capability: " + name
                             + " " + version + " -> " + after[name])
    print("PASS preserved upstream package capabilities")
