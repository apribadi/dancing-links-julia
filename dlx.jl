
module DLX

    import Base.*

    export test

    abstract Left
    abstract Right
    abstract Up
    abstract Down

    next(::Type{Left},  it) = it.left
    next(::Type{Right}, it) = it.right
    next(::Type{Up},    it) = it.up
    next(::Type{Down},  it) = it.down

    type Linked{T}
        first
        sentinel
    end

    start{T}(iter::Linked{T}) = iter.first
    done{T}(iter::Linked{T}, state) = (state == iter.sentinel)
    next{T}(iter::Linked{T}, state) = (state, next(T, state))

    function circular(T, head)
        Linked{T}(next(T, head), head)
    end

    abstract ColumnHead
    abstract RowHead

    type Root <: RowHead
        left
        right
        function Root()
            self = new()
            self.left = self.right = self
            self
        end
    end

    type Column <: ColumnHead
        right
        left
        up
        down
        size
        ci
        function Column(ci)
            self = new()
            self.ci = ci
            self.size = 0
            self.left = self.right = self.up = self.down = self
            self
        end
    end

    type Row
        head
        ri
        function Row(ri)
            self = new()
            self.ri = ri
            self.head = nothing
            self
        end
    end

    function push(head::ColumnHead, it)
        head.up.down = it
        it.up = head.up
        it.down = head
        head.up = it      # modify this last
    end

    function push(head::Column, it)
        invoke(push, (ColumnHead, Any), head, it)
        head.size += 1
    end

    function push(head::RowHead, it) 
        head.left.right = it
        it.left = head.left
        it.right = head
        head.left = it     # modify this last
    end

    function push(row::Row, it)
        if row.head == nothing
            row.head = it
        else
            invoke(push, (RowHead, Any), row.head, it)
        end
    end

    type Node <: RowHead # hack
        left
        right
        up
        down
        row
        col
        function Node(row, col)
            self = new()
            self.row = row
            self.col = col
            self.left = self.right = self.up = self.down = self
            self
        end
    end

    function init(nrows, ncols, is_constraint)
        root = Root()
        for ci in 1:ncols
            push(root, Column(ci))
        end

        for ri in 1:nrows
            row = Row(ri)
            for (col, ci) in enumerate(circular(Right, root))
                if !is_constraint(ri, ci)
                    continue
                end

                it = Node(row, col)
                push(row, it)
                push(col, it)
            end
        end

        root
    end

    function search(root)
        rows = {}
        search(root, rows, 0)
        return
    end

    function search(root, rows, n)
        if root.right == root
            println(rows)
            return
        end

        col = choose_column(root)
        cover(col)

        for row in circular(Down, col)
            push(rows, row.row.ri)
            for j in circular(Right, row)
                cover(j.col)
            end
            search(root, rows, n + 1) # check for soln?
            for j in circular(Left, row)
                uncover(j.col)
            end
            pop(rows)
        end

        uncover(col)
    end

    function cover(col)
        col.right.left = col.left
        col.left.right = col.right
        for i in circular(Down, col)
            for j in circular(Right, i)
                j.down.up = j.up
                j.up.down = j.down
                j.col.size -= 1
            end
        end
    end

    function uncover(col)
        for i in circular(Up, col)
            for j in circular(Left, i)
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

    function test()
        ex = [1 0 0 0 1
              0 1 0 1 0
              0 1 1 0 0
              0 0 1 0 0
              1 0 0 1 1]
        f = (ri, ci) -> (ex[ri, ci] == 1)
        root = init(size(ex)..., f)
        search(root)
        return
    end

end # module DLX

