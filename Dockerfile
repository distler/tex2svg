FROM debian:bullseye-slim

RUN echo "deb http://deb.debian.org/debian bullseye main" > /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list && \
    apt update -y && \
    apt install -y build-essential ruby ruby-dev ruby-bundler rubygems rake pdf2svg \
      texlive-latex-base texlive-pictures xzdec && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    tlmgr init-usertree && \
    tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2020/tlnet-final && \
    tlmgr install stix2-type1 filemod ucs currfile varwidth adjustbox standalone && \
    updmap-sys &&\
    chmod 711 /root && \
    useradd -m myuser && \
    mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY . /usr/src/app
COPY ./config.yml.docker /usr/src/app/config.yml
RUN bundle install && \
    chown -R myuser:myuser /usr/src/app/tmp

EXPOSE 9292

USER myuser
ENV TEXMFHOME /root/texmf
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0"]
