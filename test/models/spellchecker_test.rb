require 'test_helper'

class SpellcheckerTest < ActiveSupport::TestCase
	def setup
		@sp = load_spellchecker
	end
	
	test "word counting" do
		assert_equal 3, @sp.lookup("hello")
		assert_equal 3, @sp.lookup("ruby")
		assert_equal 2, @sp.lookup("rudy")
		assert_equal 1, @sp.lookup("rails")
		assert_equal 0, @sp.lookup("nothing"), "lookup missing words should return 0"
	end

	
	test "known words" do
		knowns = @sp.known(["notthere", "hello", "ruby", "nonono", "ru"])
		assert_equal ["hello", "ruby"], knowns
		
		knowns = @sp.known(["hello", "goodbye", "rude", "yayaya", "ru", "rails"])
		assert_equal ["hello", "rude", "rails"], knowns
	end
	
# all the types of 1-distance edits
	
	test "deletes" do
		edits = @sp.edits1("hel")
		assert_includes edits, "he"
		assert_includes edits, "hl"
		assert_includes edits, "el"
	end
	
	test "inserts" do
		edits = @sp.edits1("hel")
		#subset of possible includes
		inserts = ["ahel", "hkel", "herl", "helz"]
		inserts.each {|d| assert edits.include?(d) , "problem with includes: test case #{d}" }		
	end
	 
	test "transposes" do
		edits = @sp.edits1("hel")
		assert_includes edits, "ehl"
		assert_includes edits, "hle"
	end
	
	test "replaces" do
		edits = @sp.edits1("hel")
		assert_includes edits, "vel"
		assert_includes edits, "hfl"
		assert_includes edits, "hep"
	end
	
	test "correct" do
		assert_equal ["rude"], @sp.correct("rude")
		assert_equal ["ruby", "by"], @sp.correct("uby")
		assert_equal ["ruby", "rudy", "by"], @sp.correct("duy")
	end
end
