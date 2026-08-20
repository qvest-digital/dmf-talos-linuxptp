# dmf-talos-linuxptp

linuxptp on `scratch`: three statically linked binaries and a licence file,
about 1.3 MB unpacked.

It exists because immutable, container-optimised Linux distributions such as
Talos Linux have no package manager, so PTP has to arrive as a container. We
use it for SMPTE ST 2059-2 time sync on ST 2110 media networks, where PTP runs
in the host network namespace against the NIC's PTP hardware clock and pods
read the time from there.

## Image

```
ghcr.io/qvest-digital/dmf-talos-linuxptp:<version>
```

`/usr/sbin/ptp4l`, `/usr/sbin/phc2sys`, `/usr/sbin/pmc`. `ptp4l` is the
entrypoint. `/var/run` exists because `ptp4l` opens its management socket at
`/var/run/ptp4l` and there is no shell in the image to create the directory
later.

## Running

```
docker run --rm --network host \
  --cap-add NET_ADMIN --cap-add SYS_TIME \
  --device /dev/ptp0 \
  -v "$PWD/ptp4l.conf:/etc/ptp4l.conf:ro" \
  ghcr.io/qvest-digital/dmf-talos-linuxptp:<version> \
  -f /etc/ptp4l.conf -i eth0 -H
```

From the host it needs:

- the host network namespace, since PTP is exchanged on a real interface
- the PTP hardware clock of that interface as `/dev/ptpN`, for `ptp4l -H` and
  for `phc2sys`
- `CAP_NET_ADMIN`, to turn hardware timestamping on for the interface
- `CAP_SYS_TIME`. `ptp4l` needs it too, not only `phc2sys`: without it the
  kernel clock status and TAI offset cannot be set and it logs `failed to set
  the clock status: Operation not permitted` on every start

Interface names are not portable between machines. Pass `-i` at launch from
something that resolved the name on the host rather than fixing it in the
config file.

The image carries no configuration. linuxptp ships profile configs in its
source tree; mount the one you want.

## Versions

Releases are cut by release-please from Conventional Commits, and the version
is this repository's, not linuxptp's. The linuxptp version is pinned in the
`Dockerfile` and reported by `ptp4l -v`.

## Licence

GPL-2.0-or-later, following linuxptp itself. The `Dockerfile` pins the exact
upstream tag and commit the binaries are built from, and the image ships
upstream's licence text at `/usr/share/licenses/linuxptp/COPYING`.
