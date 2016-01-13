(function(window) {
	var piv = {};


	var functions = {
		add: function(a, b) { return a + b },
		sub: function(a, b) { return  a - b },
		mult: function(a, b) { return a * b }
	};

	var count = function() {
		this.val = 0;
	}
	count.prototype.add = function(val) {
		this.val ++;
	}
	count.prototype.get = function() {
		return this.val;
	}

	var sum = function() {
		this.val = 0;
	}
	sum.prototype.add = function(val) {
		this.val += val;
	}
	sum.prototype.get = function() {
		return this.val;
	}

	var avg = function() {
		this.val = 0;
		this.cnt = 0;
	}
	avg.prototype.add = function(val) {
		this.val += val;
		this.cnt ++;
	}
	avg.prototype.get = function() {
		if (this.cnt == 0) {
			return null;
		} else {
			return this.val / this.cnt;
		}
	}

	var aggregates = {
		count: count,
		sum: sum,
		avg: avg
	};

	function executeOp(op, data) {
		if (op.code == 'COL') {
			var resVect = [];
			var idx = data.colIdx[op.name];
			for (var i = 0; i < data.length; i++) {
				resVect.push(data[i][idx]);
			}
			return resVect;
		} else if (op.code == 'CONST') {
			var resVect = [];
			for (var i = 0; i < data.length; i++) {
				resVect.push(op.val);
			}
			return resVect;
		} else {
			var fn = functions[op.fn];
			var args = [];
			for (var i = 0; i < op.args.length; i++) {
				args.push(executeOp(op.args[i], data));
			}
			var resVect = [];
			for (var i = 0; i < data.length; i++) {
				var a = [];
				for (var j = 0; j < args.length; j++) {
					a.push(args[j][i]);
				}
				resVect.push(fn.apply(fn, a));
			}
			return resVect;
		}
	}

	piv.exec = function(parsed, data) {
		var fullRes = [];
		// initialize the result
		for (var i =0 ; i < data.length; i++) {
			fullRes.push([]);
		}
		var col;
		for (var i = 0; i < parsed.rows.length; i++) {
			col = executeOp(parsed.rows[i], data);
			for (var j = 0; j < col.length; j++) {
				fullRes[j].push(col[j]);
			}
		}
		for (var i = 0; i < parsed.cols.length; i++) {
			col = executeOp(parsed.cols[i], data);
			for (var j = 0; j < col.length; j++) {
				fullRes[j].push(col[j]);
			}
		}

		for (var i = 0; i < parsed.cells.length; i++) {
			col = executeOp(parsed.cells[i], data);
			for (var j = 0; j < col.length; j++) {
				fullRes[j].push(col[j]);
			}
		}

		// sort for grouping
		var groupers = parsed.rows.length + parsed.cols.length;
		fullRes.sort(function(a, b) {
			for (var i = 0; i < groupers; i++) {
				if (a[i] == b[i]) {
					continue;
				} else {
					return a[i] < b[i] ? -1 : 1;
				}
			}
			return 0;
		});

		function eq(prev, curr) {
			if (!prev) {
				return false;
			}
			for (var i = 0; i < groupers; i++) {
				if (prev[i] != curr[i]) {
					return false;
				}
			}
			return true;
		}

		var groupedResult = [];
		var prev = undefined;
		var currentRow = [];
		var currAggs = undefined;
		var aggs = parsed.cells.length;

		for (var i = 0; i < fullRes.length; i++) {
			if (eq(prev, fullRes[i])) {
				// eq rows, agg is handled below
			} else {
				// if change then store aggs
				if (currAggs) {
					for (var j = 0; j < currAggs.length; j++) {
						currentRow.push(currAggs[j].get());
					}
				}
				currentRow = [];
				for (var j = 0; j < groupers; j++) {
					currentRow.push(fullRes[i][j]);
				}
				groupedResult.push(currentRow)
				// aggregate init
				currAggs = [];
				for (var j = 0; j < aggs; j++) {
					currAggs.push(new aggregates[parsed.cells[j].agg]());
				}

			}
			for (var j = 0; j < aggs; j++) {
				currAggs[j].add(fullRes[i][j + groupers]);
			}
			prev = fullRes[i];
		}

		// last run
		if (currAggs) {
			for (var j = 0; j < currAggs.length; j++) {
				currentRow.push(currAggs[j].get());
			}
		}

		return groupedResult;
	}

	piv.execute = function(qry, data) {
	}

	piv.mkdata = function(cols, data) {
		data.cols = cols;
		data.colIdx = {};
		for (var i = 0; i < cols.length; i++) {
			data.colIdx[cols[i]] = i;
		}
		return data;
	}

	piv.col = function(name) {
		return {
			code: 'COL',
			name: name
		};
	}

	piv.op = function(fn, args) {
		return {
			code: 'OP',
			fn: fn,
			args: args
		};
	}

	piv.con = function(v) {
		return {
			code: 'CONST', 
			val: v
		};
	}

	piv.agg = function(a, exp) {
		exp.agg = a;
		return exp;
	}

	piv.qry = function(rows, cols, cells) {
		if (arguments.length == 2) {
			cells = cols;
			cols = [];
		}
		rows = rows || [];
		cols = cols || [];
		cells = cells || [];

		return {
			rows: rows,
			cols: cols,
			cells: cells
		}
	}

	window.piv = piv;
})(window)