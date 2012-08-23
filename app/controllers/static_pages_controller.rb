class StaticPagesController < ApplicationController

	attr_accessor :events

	#
	# search a user at github.com
	# if get a user with the same username, then return the user related info.
	#
	
	def github_search_user(event_id, user_name)

		user_name_url = user_name.gsub(' ', '%20')

		github_user_info = {}

		if user_name_url != nil

			begin
				client = Octokit::Client.new
				users = client.search_users(user_name_url)
			rescue StandardError => bang
				puts 'Error : ' + bang.to_s
			end

			user_count = 0

			if users!=nil and users.any?

				users.each do |user|
					
					if user['fullname']!=nil
						if user['fullname'] == user_name
							puts 'Searched a user at github : FullName = ' + user['fullname']
							
							user = Octokit.user(user['login'])

							if user.avatar_url != nil
								github_user_info = { :photo => user.avatar_url, :github_html_url => user.html_url }
								return github_user_info
							end
						end
					end

					user_count+=1
					break if user_count == 1
				end
			end
		end

		# no user be found, return a empty hash.
		return github_user_info
	end


	def home

		@events = {}

		#
		# get my rsvp upcoming events
		#

		uncoming_events = RestClient.get 'https://api.meetup.com/2/events?key=a1d1a433d01b274a182371764e7e56&rsvp=yes&status=upcoming', { :accept => :json }
		uncoming_events_json = JSON.parse(uncoming_events)

		uncoming_events_count = 0

		#
		# loop all the events
		#

		uncoming_events_json['results'].each do |event|

			puts '---------------------------------------------------------------------------'
			puts 'My RSVP Event Name : ' + event['name']

			event_name = event['name']
			id = event['id']

			@events[event_name] = Array.new

			#
			# get rsvp members for the event
			#

			rsvps = RestClient.get "https://api.meetup.com/2/rsvps?key=a1d1a433d01b274a182371764e7e56&sign=true&event_id=#{id}", { :accept => :json }
			rsvps_json = JSON.parse(rsvps)

			rsvps_member_count = 0

			#
			# loop all the members
			#

			rsvps_json['results'].each do |rsvp|

				member = rsvp['member']
				name = member['name']
				member_id = member['member_id']
				member_url = "http://www.meetup.com/members/" + "#{member_id}"

				member_photo_link = ''
				if rsvp['member_photo']!=nil
					member_photo = rsvp['member_photo'] 
					if member_photo['photo_link']!=nil
						photo_link = member_photo['photo_link']
						member_photo_link = photo_link
					end
				end

				#
				# search member name at github
				#

				github_user_photo = github_search_user(id, name)

				if github_user_photo.any?
					github_photo_url = github_user_photo[:photo]
					github_html_url  = github_user_photo[:github_html_url]

					member_info = Hash.new
					member_info = { :name => name, 
									:member_id => member_id, 
									:member_url => member_url,
									:meetup_photo_link => member_photo_link, 
									:github_photo_link => github_photo_url,
									:github_html_url => github_html_url }

					@events[event_name].push(member_info)
				end	

				rsvps_member_count += 1
				#break if rsvps_member_count == 50
			end

			uncoming_events_count += 1
			break if uncoming_events_count == 5
		end
	end
end
