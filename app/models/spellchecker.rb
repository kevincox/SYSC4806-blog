require 'set'

class Spellchecker
	ALPHABET = 'abcdefghijklmnopqrstuvwxyz'
	
	attr_reader :dictionary

	def initialize(text_file_name)
		@dictionary = Hash.new 0
		
		train_file! text_file_name
	end
	
	# Returns an array of words in the text.
	def words text
		text.downcase.scan(/[a-z]+/)
	end

	# train model (create dictionary)
	def train! word_list
		word_list.each{|w| dictionary[w] += 1 }
	end
	
	def train_file! path
		train! words File.read path
	end

	# lookup frequency of a word, a simple lookup in the @dictionary Hash
	def lookup word
		dictionary[word]
	end
	
	def edits1 word
		r = []
		
		# Deletes
		(0...word.length).each do |i|
			w = word.dup
			w[i, 1] = "".freeze
			r << w
		end
		
		# transposes
		(1...word.length).each do |i|
			w = word.dup
			w[i-1] = word[i]
			w[i]   = word[i-1]
			r << w
		end
		
		# inserts
		ALPHABET.each_char.each do |c|
			(0..word.length).each do |i|
				r << word.dup.insert(i, c)
			end
		end
		
		# replaces
		ALPHABET.each_char do |c|
			(0...word.length).each do |i|
				w = word.dup
				w[i] = c
				r << w
			end
		end
		
		r.uniq!
		r
	end
	
	def known_edits1 word
		r = edits1 word
		known! r
	end
	

	# find known (in dictionary) distance-2 edits of target word.
	def known_edits2 word
		r = edits1(word).map{|edit| known_edits1 edit}
		r.flatten!
		r.uniq!
		r
	end

	#return subset of the input words (argument is an array) that are known by this dictionary
	def known words
		words.select{|w| dictionary.include? w}
	end
	
	# if word is known, then
	# returns [word], 
	# else if there are valid distance-1 replacements, 
	# returns distance-1 replacements sorted by descending frequency in the model
	# else if there are valid distance-2 replacements,
	# returns distance-2 replacements sorted by descending frequency in the model
	# else returns nil
	def correct word
		if dictionary.include? word
			return [word]
		end
		
		edits = known_edits1 word
		unless edits.empty?
			return order! edits
		end
		
		edits = known_edits2 word
		unless edits.empty?
			return order! edits
		end
	end
	
	private
	
	def known! words
		words.select!{|w| dictionary.include? w}
		words
	end
	
	def order! words
		words.sort_by! &dictionary
		words.reverse!
		words
	end
end

