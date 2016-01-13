// helper to print the results
function doQuery(qry, ds) {

	var result = piv.exec(qry, ds);

	var resOutput = $('#output')
	resOutput.empty();

	for (var i = 0; i < result.length; i++) {
		var tr = $('<tr/>').appendTo(resOutput);
		for (var j = 0; j < result[i].length; j++) {
			$('<td/>').html(result[i][j]).appendTo(tr);
		}
	}

}



var ds = undefined; 

function updateMeta() {
	$("#metadata").html(ds.cols.join(', '));
}


function ds1() {
	// define some sample data
	var cols = ['continent', 'country', 'population'];
	var data = 
	[
		['EUR', 'Germany', 12345],
		['EUR', 'France', 1343],
		['EUR', 'UK', 1243],
		['NA', 'USA', 43222],
		['ASIA', 'China', 123123132]
	];	
	ds = piv.mkdata(cols, data);
	updateMeta();
}

ds2()

function ds2() {
	$.get('vendors_sf.csv', function(val) {
		var rows = val.split('\n');

		var cols = rows[0].split(',')
		for (var i = 0; i < cols.length; i++) {
			cols[i] = cols[i].replace(/[^a-zA-Z0-9]/g, '')
		}
		rows.splice(0, 1);
		for (var i = 0; i < rows.length; i++) {
			rows[i] = rows[i].split(',');
		}
		ds = piv.mkdata(cols, rows);
		updateMeta();
	})
}
function ds3() {
	updateMeta();
}
function ds4() {
	updateMeta();
}





$('#query1').click(ds1);
$('#query2').click(ds2);
$('#query3').click(ds3);
$('#query4').click(ds4);

$('#queryInput').on('input', function(val) {
	var value = $(val.target).val();
	if (value) {
		try {
			var parsed = hatparser.parse(value);
			$('#parseroutput').html(JSON.stringify(parsed, null, 4)).css('color', 'black');
			if (parsed.rows || parsed.cells) {
				doQuery(parsed, ds);
			}
		} catch (e) {
			$('#parseroutput').html(e.message).css('color', 'red');
			throw e;	
		}
	} else {
		$('#parseroutput').html('Please start entering your query above');
	}
});