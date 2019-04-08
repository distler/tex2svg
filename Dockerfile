FROM ruby:2.6

RUN apt-get update -y && apt-get install -y \
    rake rubygems pdf2svg texlive-latex-base\
    texlive-pictures \
    texlive-fonts-recommended xzdec \
    && rm -rf /var/lib/apt/lists/* && \
    gem update --system && gem update

RUN tlmgr init-usertree && tlmgr install mnsymbol \
    filemod ucs currfile varwidth adjustbox standalone

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app
COPY ./config.yml.docker /usr/src/app/config.yml
RUN bundle install --path vendor/bundle

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0"]
