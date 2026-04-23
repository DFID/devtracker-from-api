// AUTOCOMPLETE
var people = ['Foreign, Commonwealth and Development <br><span>Department</span>',
     'Home Office <br><span>Department</span>',
     'Department of Health and Social Care <br><span>Department</span>',
     'Department for Energy Security and Net Zero <br><span>Department</span>',
     'UK Integrated Security Fund <br><span>Department</span>',
     'Department for Science, Innovation and Technology <br><span>Department</span>',
     'Department for Environment Food and Rural Affairs <br><span>Department</span>',
     'Ministry of Housing, Communities and Local Government <br><span>Department</span>',
     'Department for Work and Pensions <br><span>Department</span>',
     'Department for Education <br><span>Department</span>',
     'HM Revenue and Customs <br><span>Department</span>',
     'Department for Culture, Media and Sport <br><span>Department</span>',
     'Office for National Statistics <br><span>Department</span>', 
     'HM Treasury <br><span>Department</span>',
     'Ministry of Defence <br><span>Department</span>',
     'Department for Business, Energy and Industrial Strategy <br><span>Department</span>',
     'Cabinet Office <br><span>Department</span>', 
     'Cross-Government Prosperity Fund <br><span>Department</span>', 
     'Department of International Trade <br><span>Department</span>', 

     'Africa <br><span>Region</span>', 
     'America <br><span>Region</span>', 
     'Asia <br><span>Region</span>', 
     'Caribbean <br><span>Region</span>', 
     'Central Asia <br><span>Region</span>', 
     'Eastern Africa <br><span>Region</span>', 
     'Europe <br><span>Region</span>', 
     'Far East Asia <br><span>Region</span>', 
     'Middle Africa <br><span>Region</span>', 
     'Middle East <br><span>Region</span>', 
     'North of Sahara <br><span>Region</span>', 
     'Oceania <br><span>Region</span>', 
     'South & Central Asia <br><span>Region</span>', 
     'South America <br><span>Region</span>', 
     'South Asia <br><span>Region</span>', 
     'South of Sahara <br><span>Region</span>', 
     'Southern Africa <br><span>Region</span>', 
     'Western Africa <br><span>Region</span>', 

     'Administration <br><span>Sector</span>', 
     'Agricultural <br><span>Sector</span>', 
     'Banking and Financial Services <br><span>Sector</span>', 
     'Budget <br><span>Sector</span>', 
     'Business <br><span>Sector</span>', 
     'Communications <br><span>Sector</span>', 
     'Disaster relief <br><span>Sector</span>', 
     'Education <br><span>Sector</span>', 
     'Energy Generation and Supply <br><span>Sector</span>', 
     'Environment <br><span>Sector</span>', 
     'Government and Civil Society <br><span>Sector</span>', 
     'Health <br><span>Sector</span>', 
     'Industry <br><span>Sector</span>', 
     'Multisector <br><span>Sector</span>', 
     'Other Social Infrastructure and Services <br><span>Sector</span>', 
     'Trade <br><span>Sector</span>', 
     'Transport and Storage <br><span>Sector</span>', 
     'Unallocated <br><span>Sector</span>', 
     'Water <br><span>Sector</span>', 

     '<span class="icon_flag Afghanistan"></span>Afghanistan <br><span>Country</span>', 
     '<span class="icon_flag Albania"></span>Albania <br><span>Country</span>', 
     '<span class="icon_flag Angola"></span>Angola <br><span>Country</span>', 
     '<span class="icon_flag Argentina"></span>Argentina <br><span>Country</span>', 
     '<span class="icon_flag Armenia"></span>Armenia <br><span>Country</span>', 
     '<span class="icon_flag Azerbaijan"></span>Azerbaijan <br><span>Country</span>', 
     '<span class="icon_flag Bangladesh"></span>Bangladesh <br><span>Country</span>', 
     '<span class="icon_flag Belarus"></span>Belarus <br><span>Country</span>', 
     '<span class="icon_flag Belize"></span>Belize <br><span>Country</span>', 
     '<span class="icon_flag Benin"></span>Benin <br><span>Country</span>', 
     '<span class="icon_flag Bhutan"></span>Bhutan <br><span>Country</span>', 
     '<span class="icon_flag Bolivia"></span>Bolivia <br><span>Country</span>', 
     '<span class="icon_flag Bosnia_and_Herzegovina"></span>Bosnia and Herzegovina <br><span>Country</span>', 
     '<span class="icon_flag Botswana"></span>Botswana <br><span>Country</span>', 
     '<span class="icon_flag Brazil"></span>Brazil <br><span>Country</span>', 
     '<span class="icon_flag Burkina_Faso"></span>Burkina Faso <br><span>Country</span>', 
     '<span class="icon_flag Burundi"></span>Burundi <br><span>Country</span>', 
     '<span class="icon_flag Cambodia"></span>Cambodia <br><span>Country</span>', 
     '<span class="icon_flag Cameroon"></span>Cameroon <br><span>Country</span>', 
     '<span class="icon_flag Canada"></span>Canada <br><span>Country</span>', 
     '<span class="icon_flag Cape_Verde"></span>Cape Verde <br><span>Country</span>', 
     '<span class="icon_flag Central_African_Republic"></span>Central African Republic <br><span>Country</span>', 
     '<span class="icon_flag Chad"></span>Chad <br><span>Country</span>', 
     '<span class="icon_flag China"></span>China <br><span>Country</span>', 
     '<span class="icon_flag Colombia"></span>Colombia <br><span>Country</span>', 
     '<span class="icon_flag Comoros"></span>Comoros <br><span>Country</span>', 
     '<span class="icon_flag Congo"></span>Congo <br><span>Country</span>', 
     '<span class="icon_flag Congo_Democratic_Republic"></span>Congo (Democratic Republic) <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 






















     'Ethiopia <span class="icon_flag Ethiopia"></span> <br><span>Country</span>', 
     'Ukraine <span class="icon_flag Ukraine"></span> <br><span>Country</span>', 
     'Yemen<span class="icon_flag Yemen"></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>', 
     '<span class="icon_flag "></span> <br><span>Country</span>'
];



function matchPeople(input) {
     var reg = new RegExp(input.split("").join("\\w*").replace(/\W/, ""), "i");
     var res = [];
     if (input.trim().length === 0) {
          return res;
     }
     for (var i = 0, len = people.length; i < len; i++) {
          if (people[i].match(reg)) {
               res.push(people[i]);
          }
     }
     return res;
}

function changeInput(val) {
     var autoCompleteResult = matchPeople(val);
     document.getElementById("autocomplete_result").innerHTML = "";
     for (var i = 0, limit = 10, len = autoCompleteResult.length; i < len  && i < limit; i++) {
          document.getElementById("autocomplete_result").innerHTML += "<a class='list-group-item list-group-item-action' href='#' onclick='setSearch(\"" + autoCompleteResult[i] + "\")'>" + autoCompleteResult[i] + "</a>";
     }
     // if (autoCompleteResult === "Ethiopia <span class="icon_flag Ethiopia"></span> <br><span>Country</span>") {
     //      document.getElementById("autocomplete_result").innerHTML += "<a class='list-group-item list-group-item-action' href='#' onclick='setSearch(\"" + autoCompleteResult[i] + "\")'>" + autoCompleteResult[i] + "</a>";
     // }
}

function setSearch(value) {
     document.getElementById('autocomplete_search').value = value;
     document.getElementById("autocomplete_result").innerHTML = "";
}
