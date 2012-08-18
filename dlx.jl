
module DLX

    import Base.*

    abstract Direction
    abstract Left  <: Direction
    abstract Right <: Direction
    abstract Up    <: Direction
    abstract Down  <: Direction

    next(::Type{Left},  it) = it.left
    next(::Type{Right}, it) = it.right
    next(::Type{Up},    it) = it.up
    next(::Type{Down},  it) = it.down

    type Linked{T}
        first
        sentinel
    end

    start{T}(iter::Linked{T}) = next(T, iter.head)
    done{T}(iter::Linked{T}, state) = (state == iter.sentinel)
    next{T}(iter::Linked{T}, state) = (state, next(T, state))

    abstract WrappedIterator

    type Circular{T} <: WrappedIterator
        wrapped
        function Circular{T}(head)
            new(Linked{T}(next(T, head), head))
        end
    end

    start(iter::WrappedIterator) = start(iter.wrapped)
    done(iter::WrappedIterator, state) = done(iter.wrapped, state)
    next(iter::WrappedIterator, state) = next(iter.wrapped, state)

    type ColumnHead 
        right
        left
        up
        down
        size
        function ColumnHead()
            self = new()
            self.size = 0
            self.left = self.right = self.up = self.down = self
            self
        end
    end

    function push(head::ColumnHead, it)
        head.up.down = it
        it.up = head.up
        it.down = head
        head.up = it # must be last
        head.size += 1
    end

    type RowHead 
        left
        right
        function RowHead()
            self = new()
            self.left = self.right = self
            self
        end
    end

    function push(head::RowHead, it) 
        head.left.right = it
        it.left = head.left
        it.right = head
        head.left = it # must be last
    end

    type Node
        right
        left
        up
        down
        row
        col
        function Node(row, col)
            self = new()
            self.row = row
            self.col = col
            self
        end
    end

    function init(nrows, ncols, is_constraint)
        root = RowHead()
        for i in 1:ncols
            push(root, ColumnHead())
        end

        for ri in 1:nrows
            row = RowHead()
            for (col, ci) in enumerate(Circular{Right}(root))
                if !is_constraint(ri, ci)
                    continue
                end

                it = Node(row, col)
                push(row, it)
                push(col, it)
            end
        end
    end

    function search(root)
        rows = {}
        search(rows, 0)
    end

    function search(root, n, rows)
        if root.right == root
            return rows # throw?
        end

        col = choose_column(root)
        cover(col)

        for row in Circular{Down}(col)
            push(rows, row)
            for j in Circular{Right}(row)
                cover(j.col)
            end
            search(root, rows, n + 1) # check for soln?
            for j in Circular{Left}(row)
                uncover(j.col)
            end
        end

        uncover(col)
    end

    function cover(col)
        col.right.left = col.left
        col.left.right = col.right
        for i in Circular{Down}(col)
            for j in Circular{Right}(i)
                j.down.up = j.up
                j.up.down = j.down
                j.col.size -= 1
            end
        end
    end

    function uncover(col)
        for i in Circular{Up}(col)
            for j in Circular{Left}(i)
                j.col.size += 1
                j.down.up = j
                j.up.down = j
            end
        end
        col.right.left = col
        col.left.right = col
    end

    function choose_column(root)
        root.right
    end

end # module DLX

import DLX.*
