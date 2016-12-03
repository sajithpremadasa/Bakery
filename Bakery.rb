#!/usr/bin/ruby

# ==================================
# Author: Sajith Premadasa
# Date  : 01 Dec 2016
# ==================================


require 'minitest/autorun'

# ==================================
# Bakery class Implementation
# Represents a certain bakery
# Bakery sells different types of
# products in differnt pack sizes
# ==================================

class Bakery
	attr_accessor	:name
	attr_accessor	:location
	attr_accessor	:store
	attr_accessor	:order_manager

	def initialize(name, location)
		@name = name
		@order_manager = OrderManager.new(self)
		@store = Store.new
	end

	def submit_order(id, items)
		@order_manager.submit_order(id, items)
	end
end

# ==================================
# Store class Implementation
# Responsible of keeping products 
# packages 
# ==================================

class Store
	attr_accessor	:products

	def initialize
		@products = []

		# ===================================================
		# Sort packs by sizes (ascending) to arrange properly
		# ===================================================

		vs = add_product('Vegemite Scroll', 'VS5')
		mb = add_product('Blueberry Muffin', 'MB11')
		cf = add_product('Croissant', 'CF')

		vs.add_package(3, 6.99)
		vs.add_package(5, 8.99)
		vs.packs.sort_by!(&:size)

		mb.add_package(2, 9.95)
		mb.add_package(5, 16.95)
		mb.add_package(8, 24.95)
		mb.packs.sort_by!(&:size)

		cf.add_package(3, 5.95)
		cf.add_package(5, 9.95)
		cf.add_package(9, 16.99)
		cf.packs.sort_by!(&:size)
	end

	def add_product(name, code)
		product = Product.new(name, code)
		@products << product
		product
	end
end

# ==================================
# OrderManager class Implementation
# Responsible of handling orders 
# from the bakery reception
# It will keep track of orders
# ==================================

class OrderManager
	attr_accessor	:bakery
	attr_accessor	:orders

	def initialize(bakery)
		@orders = []
		@bakery = bakery
	end

	def submit_order(id, items)
		ord = @orders.select{|x| x.id == id}
		if (ord.size > 0)
			return "Order id already exists!"
		end

		if (items.size > 0 )
			order = Order.new(id)
			@orders << order

			items.each do |item|
				# identify each item
				item.each do |code, qty|
					if (qty.to_i <= 0)
						return "Invalid order qty:#{qty} for #{code}"
					end

					products = bakery.store.products.select{|x| x.code == code}
					if (products[0] == nil)
						return "Invalid product code:#{code}!"
					else
						min_size = products[0].packs[0].size
						if(qty.to_i < min_size)
							return "Cannot service order as qty:#{qty} is less than the minimum sized pack:#{min_size}!"
						end

						order_item = OrderItem.new(products[0], qty)
						order.add_item(order_item)
					end
				end
			end
		elsif
			print "No items found!\n"
			return nil
		end

		package_order(id)
	end


	def package_order(id)
		order = @orders.select{|x| x.id == id}
		if (order == nil)
			print "Couldn't find the order!\n"
			return nil
		end

		if (order.size != 1)
			print "Invalid order size:#{order.size}\n";
			return nil
		end

		prices = []

		order[0].items.each do |item|
			if (item.product != nil)
				item.product.selected_packs = []
				remain = item.product.allocate(item.qty.to_i);
				if (remain.to_i != 0)
					return "Requested qty:#{item.qty} cannot be serviced by existing pack sizes!"
				end

				price = item.product.calculate()
				prices << price
				# puts "#{item.qty} #{item.product.code} = $#{price}\n"
			end
		end
	
		return prices
	end
end

# ==================================
# Order class Implementation
# order can consist of combination
# of items
# ==================================

class Order
	attr_accessor :id
	attr_accessor :items
	attr_accessor :selected_packs

	def initialize(id)
		@id = id
		@items = []
		# To store the final package arrangement
		@selected_packs = []
	end

	def add_item(item)
		@items << item
	end
end

# ==================================
# OrderItem class Implementation
# order item consists of the product
# code and the quantity needed
# ==================================

class OrderItem
	attr_accessor :code
	attr_accessor :qty
	attr_accessor :product

	def initialize(product, qty)
		@product = product
		@qty  = qty
	end
end

# ==================================
# Product class Implementation
# Product has a unique code
# ==================================

class Product
	attr_accessor	:name
	attr_accessor	:code
	attr_accessor	:packs
	attr_accessor	:selected_packs

	def initialize(name, code)
		@name  = name
		@code  = code
		@packs = []
		@selected_packs = []
	end

	def add_package(qty, price)
		pack = Pack.new(self, qty, price)
		@packs << pack 
	end

	def allocate(qty)
		remaining_qty = nil

		# ==============================================
		# packs are allocated in large packs first order
		# to minimize the packaging space
		# ==============================================
		@packs.reverse_each do |pack|
			remaining_qty = qty - pack.size

			if remaining_qty > 0
				ret_val = allocate(remaining_qty)

				if ret_val == 0
					@selected_packs << pack
					remaining_qty = 0
					break
				end
			elsif remaining_qty == 0
				@selected_packs << pack
				break
			end
		end

		remaining_qty
	end

	def calculate
		price = 0.0
		@selected_packs.each do |pack|
			price += pack.price.to_f
			# print "#{pack.size} pack\n"
		end

		price.round(2)
	end
end

# ==================================
# Pack class Implementation
# Pack contains number of products
# ==================================

class Pack
	attr_accessor	:size
	attr_accessor	:product
	attr_accessor	:price

	def initialize (product, size, price)
		@size = size.to_i
		@price = price.to_f
		@product = product
	end

	def add_product(product)
		self.product = product
	end
end

# ==================================
# Tests
# ==================================

class BakeryTest < Minitest::Test

	def setup;
		@bakery = Bakery.new('BillCap', 'Richmond')
	end

	def test_initial_setup
		assert(@bakery != nil)
		assert(@bakery.store.products.size == 3)

		assert(@bakery.store.products[0].packs.size == 2)
		assert(@bakery.store.products[1].packs.size == 3)
		assert(@bakery.store.products[2].packs.size == 3)

		assert(@bakery.store.products[0].packs[0].size == 3)
		assert(@bakery.store.products[0].packs[1].size == 5)
		assert(@bakery.store.products[0].packs[0].price == 6.99)
		assert(@bakery.store.products[0].packs[1].price == 8.99)

		assert(@bakery.store.products[1].packs[0].size == 2)
		assert(@bakery.store.products[1].packs[1].size == 5)
		assert(@bakery.store.products[1].packs[2].size == 8)
		assert(@bakery.store.products[1].packs[0].price == 9.95)
		assert(@bakery.store.products[1].packs[1].price == 16.95)
		assert(@bakery.store.products[1].packs[2].price == 24.95)

		assert(@bakery.store.products[2].packs[0].size == 3)
		assert(@bakery.store.products[2].packs[1].size == 5)
		assert(@bakery.store.products[2].packs[2].size == 9)
		assert(@bakery.store.products[2].packs[0].price == 5.95)
		assert(@bakery.store.products[2].packs[1].price == 9.95)
		assert(@bakery.store.products[2].packs[2].price == 16.99)

		assert(@bakery.store.products[0].code == 'VS5')
		assert(@bakery.store.products[1].code == 'MB11')
		assert(@bakery.store.products[2].code == 'CF')
	end

	def test_valid_order_should_be_success
		@bakery.submit_order('order_1', [{'VS5' => '10'},{'MB11' => '14'}, {'CF' => '13'}])

		# 2 * 5 packs from VS5
		assert(@bakery.store.products[0].selected_packs.size == 2)
		assert(@bakery.store.products[0].selected_packs[0].price == 8.99)
		assert(@bakery.store.products[0].selected_packs[1].price == 8.99)

		# 3 * 2 packs and 1 * 8 pack from MB11
		assert(@bakery.store.products[1].selected_packs.size == 4)
		assert(@bakery.store.products[1].selected_packs[0].price == 9.95)
		assert(@bakery.store.products[1].selected_packs[1].price == 9.95)
		assert(@bakery.store.products[1].selected_packs[2].price == 9.95)
		assert(@bakery.store.products[1].selected_packs[3].price == 24.95)

		# 1 * 3 pack and 2 * 5 pack
		assert(@bakery.store.products[2].selected_packs.size == 3)
		assert(@bakery.store.products[2].selected_packs[0].price == 5.95)
		assert(@bakery.store.products[2].selected_packs[1].price == 9.95)
		assert(@bakery.store.products[2].selected_packs[2].price == 9.95)
	end

	def test_wrong_product_id_returns_error
		rc = @bakery.submit_order('order_2', [{'ABC' => '10'},{'MB11' => '14'}, {'CF' => '13'}])
		assert(rc == "Invalid product code:ABC!")
	end

	def test_invalid_order_qty_returns_error
		rc = @bakery.submit_order('order_3', [{'VS5' => '10'},{'MB11' => '14'}, {'CF' => '0'}])
		assert(rc == "Invalid order qty:0 for CF")
	end

	def test_order_id_must_be_unique
		rc = @bakery.submit_order('order_3', [{'VS5' => '10'},{'MB11' => '14'}, {'CF' => '0'}])
		rc = @bakery.submit_order('order_3', [{'VS5' => '10'},{'MB11' => '14'}, {'CF' => '0'}])
		assert(rc == "Order id already exists!")
	end

	def test_order_qty_must_be_greater_than_minimum_pack_size
		rc = @bakery.submit_order('order_x', [{'VS5' => '2'}])
		assert(rc == "Cannot service order as qty:2 is less than the minimum sized pack:3!")
	end

	def test_orders_with_unserviceable_order_qtys_must_be_rejected
		rc = @bakery.submit_order('order_z', [{'VS5' => '4'}])
		assert(rc == "Requested qty:4 cannot be serviced by existing pack sizes!")
	end

	def test_exact_qty_of_a_pack_size_should_be_serviced
		@bakery.submit_order('order_z', [{'VS5' => '3'}])

		# 1 * 3 pack from VS5
		assert(@bakery.store.products[0].selected_packs.size == 1)
		assert(@bakery.store.products[0].selected_packs[0].price == 6.99)
	end
end
