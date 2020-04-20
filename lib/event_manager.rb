require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'



def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    
    begin
        civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def clean_phone_number(phone_number)
    phone_number.gsub!(/[^0-9]/, '')
    
    if phone_number.to_s.length < 10 
        "0000000000"
    elsif phone_number.to_s.length == 11 && phone_number.to_s[0] == "1"
        phone_number[1..-1]
    elsif phone_number.to_s.length == 11 && phone_number.to_s[0] != "1"
        "0000000000"
    elsif phone_number.to_s.length > 11
        "0000000000"
    else
        phone_number
    end

end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_reg_date(reg_date)
    DateTime.strptime(reg_date, '%m/%d/%Y %H:%M')
end


def get_reg_hour(reg_date)
    reg_date.strftime('%H')
end

def get_reg_day(reg_date)
    reg_date.wday
end

def create_hash_with_count(input_key, output_hash)
    tmp = output_hash[input_key]
    output_hash[input_key] = tmp + 1
    output_hash
end

def most_reg_by(hash)
    most_reg_array = []
    hash.each {|key, value| most_reg_array << key if value == hash.values.max}
    most_reg_array
end

def day_as_integer_to_name(array)
    return_array = []
    array.each_with_index do |value, index|
        return_array << Date::DAYNAMES[array[index]]
    end

    return_array

end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter


reg_hour_hash = Hash.new(0)
reg_day_hash = Hash.new(0)

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = clean_phone_number(row[:homephone])

    # turns row[:reg_date] into a datetime object
    reg_date = clean_reg_date(row[:regdate])


    #returns the hour for each row, so that it can be counted
    reg_hour = get_reg_hour(reg_date)

    # adds hour to hash if it doesn't exists and increments value based on frequency
    reg_hour_hash = create_hash_with_count(reg_hour, reg_hour_hash)

    # returns day, adds to hash, increments
    reg_day = get_reg_day(reg_date)
    reg_day_hash = create_hash_with_count(reg_day, reg_day_hash)

    
    legislators = legislators_by_zipcode(zipcode)


    puts phone_number
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
end


hours_with_most_reg_array = most_reg_by(reg_hour_hash)

days_with_most_reg_array = most_reg_by(reg_day_hash)
most_reg_dayname_array = day_as_integer_to_name(days_with_most_reg_array)


puts "Hours with the most registrations: #{hours_with_most_reg_array}"
puts "Days with the most registrations: #{most_reg_dayname_array}"
