require 'rmagick'
require 'fileutils'
require 'erb'
require 'rexml/document'
require 'yaml'

class Waldo

  @@template  = <<EOF
# .waldo
# 
# Please fill in fields like this:
#
#  cache: c:/waldo/cache
#  thumb: c:/waldo/thumb
#  waldoized: c:/waldo/waldoized
#
cache: 
thumb: 
waldoized: 
EOF

  attr_reader :photos, :config
  
  def initialize
    @config = create_or_find_config
    @photos = Array.new
    load_photo_data
  end
  
  # Move these to waldo gem
  def waldoize(photo_id,size)
    amount = config['colorize_percentage']
    file = Magick::Image.read("#{config['thumb']}/#{photo_id}.jpg").first
    mosaic = Magick::Image.new(file.columns * size, file.rows * size)
      
    file.rows.times {|y|
      file.columns.times {|x|
        pixel_color = file.pixel_color(x,y)
        color = Pixel.as_int(pixel_color)
        match = find_closest_photo(photos, color)
        # Load the matching 75x75 version of the photo
        thumb = Magick::Image.read("#{config['cache']}/#{match.external_id}.jpg").first
        # Delete the thumbnail from the list once it has been used
        delete_from_photos(match)
        # Convert it to gray
        gray = thumb.quantize(256, Magick::GRAYColorspace)
        # Colorize the gray version to match the current pixel color
        colorized = gray.colorize(amount, amount, amount, '#' + to_hex(pixel_color.red, pixel_color.green, pixel_color.blue))
        # Add the colorized version of the photo to the final image
        colorized.rows.times {|ty|
          colorized.columns.times {|tx|
            mosaic.pixel_color((x*size) + tx, (y*size) + ty, Magick::Pixel.new(colorized.pixel_color(tx,ty).red, colorized.pixel_color(tx,ty).green, colorized.pixel_color(tx,ty).blue, 0))
          }
        }
      }
    }
    mosaic.write("waldo_#{photo_id}.jpg")
  end
  
  def build_xml_cache
    photos = loadCache
    xml_data = Array.new
    for photo in photos
      photo_median_data = Array.new
      file = Magick::Image.read("#{photo}").first
      file.rows.times {|y|
        file.columns.times {|x|
          pixel_color = file.pixel_color(x,y)
          color = Pixel.as_int(pixel_color)
          photo_median_data << color
        }
      }
      photo_median_data.sort!
      xml_data << PhotoXML.new(photo, photo_median_data[photo_median_data.size / 2])
    end
    # xml = REXML::Document.new(File.open("#{@config['xml']}"))
    File.open("#{@config['xml']}", 'wb') do |dest|
      dest.write ERB.new(File.open('cache.xml').read, nil, '-').result(binding)
    end
  end
  
  def loadCache
    jpgfiles = File.join(config['cache'], "*.jpg")
    Dir.glob(jpgfiles)
  end
  
  protected

  def find_closest_photo(photos, color)
    if (photos.size == 1)
      photos[0]
    elsif photos[photos.size/2].median_int > color
      find_closest_photo(photos.values_at(0...((photos.size/2))), color)
    else
      find_closest_photo(photos.values_at(photos.size/2...photos.size), color)
    end
  end
  
  def to_hex(red, green, blue)
    base = 16
    "#{red.to_s(base=base).rjust(2, '0')}#{green.to_s(base=base).rjust(2, '0')}#{blue.to_s(base=base).rjust(2, '0')}"
  end
  
  def create_grey(photo, size)
    if (!File.exists?("public/images/#{size}/#{photo.external_id}.jpg"))
      image = Magick::Image.read("public/images/cache/#{photo.external_id}.jpg").first  
      image.resize!(size,size)
      grey = image.quantize(256, Magick::GRAYColorspace)
      grey.write("public/images/#{size}/#{photo.external_id}.jpg")
    end
  end
  
  def create_or_find_config
    home = ENV['HOME'] || ENV['USERPROFILE'] || ENV['HOMEPATH']
    begin
      config = YAML::load open(home + "/.waldo")
    rescue
      open(home + '/.waldo','w').write(@@template)
      config = YAML::load open(home + "/.waldo")
    end
            
    if config['cache'] == nil or config['thumb'] == nil
      puts "Please edit ~/.waldo to include your flickr api_key and secret\nTextmate users: mate ~/.waldo"
      exit(0)
    end
            
    config
  end
  
  private
  
  def load_photo_data
    xml = REXML::Document.new(File.open("#{@config['xml']}"))
    xml.elements.each("//photo") {|photo| photos << Photo.new(photo) }
    # Sort photos by median_int
    photos.sort!{|x,y| x.median_int <=> y.median_int}
  end
  
  def delete_from_photos(photo)
    photos.delete(photo)
    if (photos.size == 0)
      load_photo_data
    end
  end

end

class Pixel
  def self.as_int(pixel)
    base = 16
    "#{pixel.red.to_s(base=base).rjust(2, '0')}#{pixel.green.to_s(base=base).rjust(2, '0')}#{pixel.blue.to_s(base=base).rjust(2, '0')}".to_i(16)
  end
end

#    xml.elements.each("//photo") {|photo| Photo.create(:external_id => photo.attributes['id'].split('.').first,
#                                                       :mean => photo.attributes['a'],
#                                                       :median => photo.attributes['m'],
#                                                       :mean_red => photo.attributes['ar'],
#                                                       :mean_green => photo.attributes['ag'],
#                                                       :mean_blue => photo.attributes['ab'],
#                                                       :median_red => photo.attributes['mr'],
#                                                       :median_green => photo.attributes['mg'],
#                                                       :median_blue => photo.attributes['mb'])}
class Photo
  attr_reader :external_id, :mean, :median, :mean_red, :mean_green, :mean_blue, :median_red, :median_green, :median_blue

  def initialize(photo)
    @external_id = photo.attributes['id'].split('.').first
    @mean = photo.attributes['a']
    @median = photo.attributes['m']
    @mean_red = photo.attributes['ar']
    @mean_green = photo.attributes['ag']
    @mean_blue = photo.attributes['ab']
    @median_red = photo.attributes['mr']
    @median_green = photo.attributes['mg']
    @median_blue = photo.attributes['mb']
  end
  
  def median_int
    median.to_i(16)
  end
end

class PhotoXML
  attr_reader :external_id, :median
  
  def initialize(photo, median)
    @external_id = photo.slice(photo.rindex('/') + 1, photo.size)
    @median = median
  end  

end
