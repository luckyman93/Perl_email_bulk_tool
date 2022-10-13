var csv_contents;
var lines;
var success_lines = [];
var failur_lines = [];

function process_chunk(i) {
    // Don't do anything if we've reached the end of the list
    if ( i > lines.length ) {
        document.getElementById("send_progress").value = lines.length;

        document.getElementById('progress_indicator').style.background = '#cfc';
        document.getElementById('send_notice').style.display = 'none';
        document.getElementById('send_header').innerHTML = "Sending complete!";

        // Display the success information
        document.getElementById("success_information").style.display = "block";

        // enable HTML form inputs
        document.getElementById("subject").disabled = false;
        document.getElementById("csv_file").disabled = false;
        document.getElementById("link_uri").disabled = false;
        document.getElementById("image_file").disabled = false;

        document.getElementById("success_nums").innerHTML = success_lines.length;

        if ( failur_lines.length !== 0) {
          document.getElementById("error_info").style.display='block';
          document.getElementById("error_list").appendChild(error_table());
        } else {
          document.getElementById("error_info").style.display='none';
        }

        // reset variable
        success_lines = [];
        failur_lines = [];
      
        return
    }
    
    document.getElementById("send_progress").value = i;
    var segment = lines.slice(i, i+10)
    var r = segment.join("\n")

    var data = new FormData()
    data.append("subject", document.getElementById("subject").value);
    data.append("image_file", document.getElementById("image_file").files[0]);
    data.append("link_uri", document.getElementById("link_uri").value);
    data.append("recipients", r);

    var xhr = new XMLHttpRequest();
    // When this call has finished, process the next chunk
    xhr.addEventListener( 'loadend', () => {process_chunk(i+10)})
    xhr.open('POST', '/send_batch');
    xhr.send(data);
    xhr.onload = function () {

      // Process our return data
      if (xhr.status >= 200 && xhr.status < 300) {
        // Runs when the request is successful
        var result = JSON.parse(xhr.responseText).results;
        collect_json(result);
      } else {
        // Runs when it's not
        console.log(JSON.parse(xhr.responseText));
      }
    
    };
}

function process_form(e) {
    if ( !document.getElementById("subject").value
      || document.getElementById("image_file").files.length < 1
      || document.getElementById("csv_file").files.length < 1
    ) {
        return false
    }

    // We don't want this form to do anything automatically
    e.preventDefault();

    // Disable the submit button so they can't double-send
    document.getElementById("submit_button").disabled = true;

    // Disable the HTML form inputs so they can't change the details mid-way through
    document.getElementById("subject").disabled = true;
    document.getElementById("csv_file").disabled = true;
    document.getElementById("link_uri").disabled = true;
    document.getElementById("image_file").disabled = true;

    // Display the progress box
    document.getElementById("progress_indicator").style.display = "block";

    // Prepare the data
    lines = csv_contents.split(/\r?\n/);

    // Set up the progress bar
    var progress_bar = document.getElementById("send_progress")
    progress_bar.max = lines.length;
    progress_bar.value = 0;

    // Process the first chunk of recipients
    process_chunk(0);

    return false;
}

function csv_selected() {
  const [file] = document.getElementById("csv_file").files;
  const reader = new FileReader();

  reader.addEventListener("load", () => {
      csv_contents = reader.result;

      // Enable the submit button
      document.getElementById("submit_button").disabled = false;
  }, false);

  if (file) {
      reader.readAsText(file);
  }
}

// collect json by success type
function collect_json(result) {
  result.forEach(element => {
    if ( element[0].success == 0 ) {
      failur_lines.push(element[0]);
    } else {
      success_lines.push(element[0]);
    };
  });
}

// create error table
function error_table() {
  var table = document.createElement('table'), tr, td, row;
      tr = document.createElement('tr');
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = "No";
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = "Email";
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = "Status";
    table.appendChild(tr);
  for (row = 0; row < failur_lines.length; row++) {
      tr = document.createElement('tr');
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = row + 1;
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = failur_lines[row].email;
        td = document.createElement('td');
        tr.appendChild(td).innerHTML = "failur";
    table.appendChild(tr);
  }
  return table;
}

(function() {
  document.getElementById("csv_file").addEventListener("change", csv_selected);
  document.getElementById("submit_button").addEventListener("click", process_form);
})();
