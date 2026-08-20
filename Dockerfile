# linuxptp, built statically against musl and shipped on scratch.
ARG ALPINE_VERSION=3.21

FROM alpine:${ALPINE_VERSION} AS build

# Upstream linuxptp, pinned to a release tag and verified by the commit that
# tag points at. The tag is the source this image redistributes; see LICENSE.
ARG LINUXPTP_REPO=https://github.com/richardcochran/linuxptp.git
ARG LINUXPTP_REF=v4.4
ARG LINUXPTP_COMMIT=0188667308e62b6ac61151193320ec052e2fd023

RUN apk add --no-cache build-base git linux-headers bsd-compat-headers

WORKDIR /src
RUN git clone --depth 1 --branch "${LINUXPTP_REF}" "${LINUXPTP_REPO}" . \
    && test "$(git rev-parse HEAD^{commit})" = "${LINUXPTP_COMMIT}"

RUN make -j"$(nproc)" EXTRA_LDFLAGS=-static ptp4l phc2sys pmc

# Staged root. /var/run has to exist: ptp4l opens its management socket at
# /var/run/ptp4l and there is no shell in the final image to create it.
RUN mkdir -p /out/usr/sbin /out/var/run /out/usr/share/licenses/linuxptp \
    && cp ptp4l phc2sys pmc /out/usr/sbin/ \
    && strip /out/usr/sbin/ptp4l /out/usr/sbin/phc2sys /out/usr/sbin/pmc \
    && cp COPYING /out/usr/share/licenses/linuxptp/COPYING \
    && for b in ptp4l phc2sys pmc; do \
         ldd "/out/usr/sbin/$b" 2>&1 | grep -q "Not a valid dynamic program" \
           || { echo "ERROR: $b is not statically linked"; exit 1; }; \
       done

FROM scratch
LABEL org.opencontainers.image.title="linuxptp" \
      org.opencontainers.image.description="linuxptp built statically and shipped on scratch" \
      org.opencontainers.image.source="https://github.com/qvest-digital/dmf-talos-linuxptp" \
      org.opencontainers.image.licenses="GPL-2.0-or-later"
COPY --from=build /out/ /
ENTRYPOINT ["/usr/sbin/ptp4l"]
