class_name DEPQ

# Double-ended priority queue using standart array and standart custom_sort() function

# It can be very slow if constantly toogle _unsorted flag, but almost as fast as heap if used correctly
# Try to awoid getting queue values such as min/max value/priority after queue modification
# Wrong way to use:
#	add("element0", 0)
#	pop_min()
#	add("element1", 1)
#	peek_min()
#	add("element2", 2)
#	change_priority("element2", 2)
#	pop_max_array()
#	peek_max_priority()
# Right way to use:
#	add("element0", 0)
#	add("element1", 1)
#	add("element2", 2)
#	change_priority("element2", 2)
#	peek_min()
#	pop_min()
#	pop_max_array()
#	peek_max_priority()


# Private variables
var _queue    : Array = []              # array of arrays [element, priority]
var _unsorted : bool  = false           # queue sorting flag, to reduce sort calls
var _size     : int   = 0               # it is faster than call _queue.size()



# Add element with priority to queue
func add(element, priority) -> void:
	_queue.append([element, priority])
	_size += 1
	_unsorted = true


# Return true if queue is empty
func empty() -> bool:
	return _size == 0


# Return number of elements in queue
func size() -> int:
	return _size


# Return element with least priority and remove it from queue
# Return null and print error if queue is empty
func pop_min():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	_size -= 1
	return _queue.pop_front()[0]


# Return element with least priority
# Return null and print error if queue is empty
func peek_min():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	return _queue[0][0]


# Return least priority value
# Return null and print error if queue is empty
func peek_min_priority():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	return _queue[0][1]


# Return array of elements with least priority and remove these elements from queue
func pop_min_array() -> Array:
	if empty():
		return []
	var array : Array  = []
	var priority = peek_min_priority()
	while peek_min_priority() == priority:
		array.append(pop_min())
		if empty():
			break
	return array


# Return array of elements with least priority
func peek_min_array() -> Array:
	if empty():
		return []
	var _temp_queue : Array  = _queue.duplicate()
	var _temp_size = int(_size)
	var array : Array = []
	var priority = peek_min_priority()
	while peek_min_priority() == priority:
		array.append(pop_min())
		if empty():
			break
	_queue = _temp_queue
	_size = _temp_size
	return array


# Return element with highest priority and remove it from queue
# Return null and print error if queue is empty
func pop_max():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	_size -= 1
	return _queue.pop_back()[0]


# Return element with highest priority
# Return null and print error if queue is empty
func peek_max():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	return _queue[-1][0]


# Return highest priority value
# Return null and print error if queue is empty
func peek_max_priority():
	if empty():
		push_error("Queue is empty")
		return null
	if _unsorted:
		sort()
	return _queue[-1][1]


# Return array of elements with highest priority and remove these elements from queue
func pop_max_array() -> Array:
	if empty():
		return []
	var array : Array  = []
	var priority = peek_max_priority()
	while peek_max_priority() == priority:
		array.append(pop_max())
		if empty():
			break
	return array


# Return array of elements with highest priority
func peek_max_array() -> Array:
	if empty():
		return []
	var _temp_queue : Array  = _queue.duplicate()
	var _temp_size = int(_size)
	var array : Array = []
	var priority = peek_max_priority()
	while peek_max_priority() == priority:
		array.append(pop_max())
		if empty():
			break
	_queue = _temp_queue
	_size = _temp_size
	return array


# Find priority of element
# Return null if there's not such element in queue
func find_priority(element):
	for i in _queue:
		if i[0] == element:
			return i[1]
	return null


# Find element with such priority
# Return null if there's not such priority in queue
func find_value(priority):
	for i in _queue:
		if i[1] == priority:
			return i[0]
	return null


# Change current priority of element to new_priorty
# Return true if priority is changed  
# Return false if priority is not changed for some reason  
func change_priority(element, new_priority) -> bool:
	for i in _queue:
		if i[0] == element:
			i[1] = new_priority
			_unsorted = true
			return true
	return false


# Merge queue from another PriorityQueueDEPQ to this queue
func merge(queue : DEPQ) -> void:
	_queue += queue._queue
	_unsorted = true


# Clear queue
func clear() -> void:
	_queue.clear()
	_unsorted = false
	_size = 0


# Calls forced queue sorting
func sort() -> void:
	_queue.sort_custom(_sort_custom)
	_queue.sort_custom(_sort_custom) # sometimes one sort_custom() is not enough for some reason
	_unsorted = false


# Return arrays of Dictionaries ("element-priority")
func get_array_dict() -> Array:
	var array : Array = []
	for i in _size:
		array.append({"element": _queue[i][0], "priority": _queue[i][1]})
	return array


# Private sort function
static func _sort_custom(a, b) -> bool:
	return a[1] < b[1]
