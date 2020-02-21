ARG ffmpeg_tag=4.2-ubuntu
ARG sonarr_tag=latest
FROM jrottenberg/ffmpeg:${ffmpeg_tag} as ffmpeg
FROM linuxserver/sonarr:${sonarr_tag}
LABEL maintainer="mdhiggins <mdhiggins23@gmail.com>"

# Add files from ffmpeg
COPY --from=ffmpeg /usr/local/ /usr/local/

ENV SMAPATH /usr/local/sma
ENV SMARS Sonarr

# get python3 and git, and install python libraries
RUN \
  apt-get update && \
  apt-get install -y \
    git \
    wget \
    python3 \
    python3-pip && \
# make directory
  mkdir ${SMAPATH} && \
# download repo
  git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMAPATH} && \
# create logging directory
  mkdir -p /var/log/sickbeard_mp4_automator && \
  touch /var/log/sickbeard_mp4_automator/index.log && \
  chgrp -R users /var/log/sickbeard_mp4_automator && \
  chmod -R g+w /var/log/sickbeard_mp4_automator && \
# install pip, venv, and set up a virtual self contained python environment
  python3 -m pip install --user --upgrade pip && \
  python3 -m pip install --user virtualenv && \
  python3 -m virtualenv ${SMAPATH}/env && \
  ${SMAPATH}/env/bin/pip install requests \
    requests[security] \
    requests-cache \
    babelfish \
    tmdbsimple \
    guessit \
    mutagen \
    subliminal \
    stevedore \
    python-dateutil \
    setuptools \
    qtfaststart && \
# ffmpeg
  chgrp users /usr/local/bin/ffmpeg && \
  chgrp users /usr/local/bin/ffprobe && \
  chmod g+x /usr/local/bin/ffmpeg && \
  chmod g+x /usr/local/bin/ffprobe && \
# cleanup
  apt-get purge --auto-remove -y && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

RUN \
	apt-get update -y && \
	apt-get install -y --no-install-recommends libva-drm2 libva2 i965-va-driver && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

EXPOSE 8989

VOLUME /config

# update.py sets FFMPEG/FFPROBE paths, updates API key and Sonarr/Radarr settings in autoProcess.ini
COPY extras/ ${SMAPATH}/
COPY root/ /
