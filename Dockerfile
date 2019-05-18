FROM ruby:2.6

RUN apt-get update -y && apt-get install -y \
    rake rubygems pdf2svg texlive-latex-base\
    texlive-pictures \
    texlive-fonts-recommended xzdec \
    && rm -rf /var/lib/apt/lists/* && \
    gem update --system && gem update

RUN tlmgr init-usertree && tlmgr install stix2-type1 \
    filemod ucs currfile varwidth adjustbox standalone

RUN updmap-sys

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app
COPY ./config.yml.docker /usr/src/app/config.yml
RUN bundle install --path vendor/bundle
RUN useradd -m myuser && chown -R myuser:myuser /usr/src/app/tmp && \
    chmod 711 /root

EXPOSE 9292

USER myuser
ENV TEXMFHOME /root/texmf
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0"]
