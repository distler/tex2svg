$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'sinatra'
require 'tex_sanitizer'
require 'tex_template'
require "sinatra/config_file"
require 'digest'

class TeX2SVG < Sinatra::Base
  register Sinatra::ConfigFile

  Version = '1.0.10'
  config_file 'config.yml'
  pdflatex = settings.pdflatex
  pdf2svg = settings.pdf2svg
  max_length = settings.max_length
  max_cpu = settings.max_cpu
  usr_tikz_commands = settings.additional_tikz_commands
  set :bind, settings.interface
  set :port, settings.port

  %i(get post).each do |method|
    send method, '/' do
      response.headers['Server'] = "tex2svg #{Version}"
      tex = params['tex']
      type = params['type']
      type.strip! if type
      type = 'tikzpicture' unless type && ['tikzcd', 'xypic'].include?(type)
      if (tex && tex.length <= max_length)
        tex.strip!
        case type
          when 'tikzpicture'
            san = TeXSanitizer.new(tex,
              TeXSanitizer::Itex_control_sequences + TeXSanitizer::Tikzpicture_control_sequences + usr_tikz_commands,
              TeXSanitizer::Itex_environments + TeXSanitizer::Tikz_environments)
            clean = TeXTemplate.tikzpicture(san.sanitize)
          when 'tikzcd'
            san = TeXSanitizer.new(tex,
              TeXSanitizer::Itex_control_sequences + TeXSanitizer::Tikzpicture_control_sequences +
              TeXSanitizer::Tikzcd_control_sequences + usr_tikz_commands,
              TeXSanitizer::Itex_environments + TeXSanitizer::Tikz_environments)
            clean = TeXTemplate.tikzcd(san.sanitize)
          when 'xypic'
        end
        i = Digest::SHA2.hexdigest(rand(1000000).to_s)
        File.open("tmp/#{i}.tex", 'w') {|f| f.print(clean)}
        system("#{pdflatex} --interaction=batchmode #{i}.tex; #{pdf2svg} #{i}.pdf #{i}.svg", {:rlimit_cpu=>max_cpu, :chdir=>'tmp'})
        if File.exist?("tmp/#{i}.svg")
          File.open("tmp/#{i}.svg") {|f| clean = f.readlines.join}
        else
          clean = "No SVG file was generated.\n"
        end
        %w[tex aux pdf log svg].each {|ext| File.delete("tmp/#{i}.#{ext}") if File.exist?("tmp/#{i}.#{ext}")}
        clean
      else
        "TeX fragment must be less than #{max_length} characters. Yours was #{tex.length}.\n" if (tex && tex.length > max_length)
      end
    end
  end
end
