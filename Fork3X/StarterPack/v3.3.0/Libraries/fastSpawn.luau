--- An expensive way to spawn a function. However, unlike spawn(), it executes on the same frame, and
-- unlike coroutines, does not obscure errors
-- @module fastSpawn

return task.spawn