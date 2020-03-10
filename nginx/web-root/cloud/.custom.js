// function definitions
var startTime, endTime;
function start() {
  startTime = new Date();
};
function end() {
  endTime = new Date();
  var timeDiff = endTime - startTime; //in ms
  alert(timeDiff + " ms");
}
function getsize(size) {
        var s = size.substring(0, size.length-1) ;
        var t = size.slice(-1) ;
        if (t == "K") {
                return Math.round(s * 1024);                
        }
        else if (t == "M") {
                return Math.round(s * 1024 * 1024);
        }
        else if (t == "G") {
                return Math.round(s * 1024 * 1024 * 1024);
        }
        else if (t == "T") {
                return Math.round(s * 1024 * 1024 * 1024 * 1024);
        }
        else {
                return Math.round(s);
        }
}
function get_cumsize(size) {
        if (size/1024 < 1) {
                return Math.round(size) + "B" ;
        }
        else if (size/1024/1024 < 1) {
                return Math.round(size/1024) + "K" ;
        }
        else if (size/1024/1024/1024 < 1) {
                return Math.round(10 * size/1024/1024)/10 + "M" ;
        }
        else if (size/1024/1024/1024/1024 < 1) {
                return Math.round(100 * size/1024/1024/1024)/100 + "G" ;
        }
        else if (size/1024/1024/1024/1024/1024 < 1) {
                return Math.round(1000 * size/1024/1024/1024/1024)/1000 + "T" ;
        }         
}
function basename(path) {
   return path.split('/').reverse()[1];
}
(function ($) {
    $.fn.rotationDegrees = function () {
         var matrix = this.css("-webkit-transform") ||
    this.css("-moz-transform")    ||
    this.css("-ms-transform")     ||
    this.css("-o-transform")      ||
    this.css("transform");
    if(typeof matrix === 'string' && matrix !== 'none') {
        var values = matrix.split('(')[1].split(')')[0].split(',');
        var a = values[0];
        var b = values[1];
        var angle = Math.round(Math.atan2(b, a) * (180/Math.PI));
    } else { var angle = 0; }
    return angle;
   };
}(jQuery));
// from https://stackoverflow.com/questions/26246601/wildcard-string-comparison-in-javascript
function matchRuleExpl(str, rule) {
  // for this solution to work on any string, no matter what characters it has
  var escapeRegex = (str) => str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");

  // "."  => Find a single character, except newline or line terminator
  // ".*" => Matches any string that contains zero or more characters
  rule = rule.split("*").map(escapeRegex).join(".*");

  // "^"  => Matches any string with the following at the beginning of it
  // "$"  => Matches any string with that in front at the end of it
  rule = "^" + rule + "$"

  //Create a regular expression object for matching string
  var regex = new RegExp(rule);

  //Returns true if it finds a match, otherwise it returns false
  return regex.test(str);
}
// display path information
var a = window.location.pathname
a = decodeURI(a)
var path = a.split('/')
path.shift()
path.shift()
path.unshift(".")
var parentDir = path.join("/")
path.shift()
path.unshift("/.cloud01")
var pathName = path.join("/")
path.shift()
path.unshift("/.cloud02")
var pathDate = path.join("/")
path.shift()
path.unshift("/.cloud03")
var pathSize = path.join("/")
document.getElementById("cwd").innerHTML = basename(a).toUpperCase(); 
document.getElementById("sortname").href = pathName; 
document.getElementById("sortdate").href = pathDate; 
document.getElementById("sortsize").href = pathSize;
// clickable path
a = window.location.pathname
var path_array = a.split('/')
var parentdir = path_array[1];
var user = path_array[2];
var new_array = [];
path_array.pop();
for (var i = 1; i < path_array.length; i++) {
        new_array.push(path_array[i])
        $("#dirinfo").before('<a class="clickpath" href=/' + new_array.join("/") + '> ' + decodeURI(path_array[i]) + ' </a>' + "|")
}
$("a.clickpath").eq(0).html('&nbsp;&lt&gt ')
// shortcut panels
function createpanels(){
	var libpath = "/" + ".cloud02" + "/" + user + "/tmp";
	var parentdir2 = ".cloud01";
	$('<div id=\"panel01\" style=\"display:none\"><a class="cloudlib all" href="' + libpath + '">&nbsp;<>&nbsp;</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a class="cloudlib auds" href="' + libpath + '/auds">auds</a>&nbsp;&nbsp;&nbsp;<a class="cloudlib docs" href="' + libpath + '/docs">docs</a>&nbsp;&nbsp;&nbsp;<a class="cloudlib pics" href="' + libpath + '/pics">pics</a>&nbsp;&nbsp;&nbsp;<a class="cloudlib vids" href="' + libpath + '/vids">vids</a></div>').insertAfter($("#dirinfo"))
}
createpanels();
// panel & menu display conditions
if ( typeof path_array[2] !== 'undefined' && path_array[2] !== "guest" ) {
        $('#panel01').css("display","block");
}
if ( user == "guest" ) { $("#dropdown").css("display","none")}
// shortcut panel highlighting
if ( path_array[3] == "tmp" ) {
        if ( typeof path_array[4] === 'undefined' ) {
                $('#panel01').find("a.all").css("background-color", "#0d0").css("color","#000").css("border","6px solid #0d0");
        } 
        else if ( path_array[4] == "auds" ) {
                $('#panel01').find("a.auds").css("background-color", "#0d0").css("color","#000").css("border","6px solid #0d0");
        }
        else if ( path_array[4] == "docs" ) {
                $('#panel01').find("a.docs").css("background-color", "#0d0").css("color","#000").css("border","6px solid #0d0");
        }
        else if ( path_array[4] == "pics" ) {
                $('#panel01').find("a.pics").css("background-color", "#0d0").css("color","#000").css("border","6px solid #0d0");
        }
        else if ( path_array[4] == "vids" ) {                
                $('#panel01').find("a.vids").css("background-color", "#0d0").css("color","#000").css("border","6px solid #0d0");
        }
}
// switch list mode vs image mode
// ENTRY01
var x = 0;
if (x == 1) {
        document.getElementById("mode").src="/cloud/.icons/view-list-icons.png";
} else {
        document.getElementById("mode").src="/cloud/.icons/view-list-compact.png";
}

// global vars
var href;
var hrefsplit;
var href_full;
var href_thumb;
var imgiter_prev = imgiter - 1;
var imgiter_next = imgiter + 1;
var isimg = 0;
//var imgformats = ["jpg", "jpeg", "png", "bmp", "tif", "gif", "fpx", "pcd", "svg", "pdf", "doc", "ppt", "xls", "docx", "pptx", "xlsx", "txt", "ppsx", "pps", "jfif", "odt"]; //because of libreoffice convert bug under raspbian buster
var imgformats = ["jpg", "jpeg", "png", "bmp", "tif", "gif", "fpx", "pcd", "svg", "pdf", "jfif"];
var fileExt;
var imgiter = 0;
var lastobj;
var n_dirs = 0;
var n_files = 0;
var cum_size = 0;
var img_w0 = Math.max(document.documentElement.clientWidth, window.innerWidth || 0) * 0.96;
var img_h0 = Math.max(document.documentElement.clientHeight, window.innerHeight || 0) * 0.98;
var img_w = img_w0;
var img_h = img_h0;
var img_width0 = img_w0;
var img_height0 = img_h0;
var img_width = img_width0;
var img_height = img_height0;
var deg = 0;
var scale_val = 0;

document.addEventListener("DOMContentLoaded", function() {
  yall({
    observeChanges: true
  });
});

 // function image viewer
        function imgview() {        
                $( "tr.insert" ).on( "click", "a.cssbox_zoomin", function( event ) {
                        scale_val = (scale_val - 0.1 ) % 0.4;
                        $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").css({"transform": "translate(-50%, -50%) rotate(" + deg + "deg) scale(" + (scale_val + 1) + ")", "max-width": img_w, "max-height": img_h, "width": img_width, "height": img_height});
                });
                $( "tr.insert" ).on( "click", "a.cssbox_rotate-reset", function( event ) {
                        deg = 0;
                        scale_val = 0;
                        setimgsize();
                        $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").css({"transform": "translate(-50%, -50%) rotate(" + deg + "deg) scale(" + (scale_val + 1) + ")", "max-width": img_w, "max-height": img_h, "width": img_width0, "height": img_height0});
                });
                $( "tr.insert" ).on( "click", "a.cssbox_rotate-right", function( event ) {
                        deg = $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").rotationDegrees();
                        deg = (deg + 90) % 360;
                        setimgsize();
                        $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").css({"transform": "translate(-50%, -50%) rotate(" + deg + "deg) scale(" + (scale_val + 1) + ")", "max-width": img_w, "max-height": img_h, "width": img_width, "height": img_height});
                });
                $( "tr.insert" ).on( "click", "a.cssbox_rotate-left", function( event ) {
                        deg = $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").rotationDegrees();
                        deg = (deg - 90) % 360;  
                        setimgsize();
                        $(this).siblings().eq(0).children("span.cssbox_full").children("img.img_full").css({"transform": "translate(-50%, -50%) rotate(" + deg + "deg) scale(" + (scale_val + 1) + ")", "max-width": img_w, "max-height": img_h, "width": img_width, "height": img_height});
                });
                $( "tr.insert" ).on( "click", "a.cssbox_next", function( event ) {
                        deg = 0;
                        scale_val = 0;
                        var nxt = ($(this).attr("href"));
                        var dom = $('' + nxt).find("img.img_full");
                        var datasrc = dom.attr("data-src");
                        dom.attr("src",datasrc);
                });
                $( "tr.insert" ).on( "click", "a.cssbox_prev", function( event ) {
                        deg = 0;
                        scale_val = 0;
                        var prv = ($(this).attr("href"));
                        var dom =  $('' + prv).find("img.img_full");
                        var datasrc = dom.attr("data-src");
                        dom.attr("src",datasrc);
                });
                $( "tr.insert" ).on( "click", "a.cssbox_close", function( event ) {
                        deg = 0;
                        scale_val = 0;
                });
                $( "tr.insert" ).on( 'click', "img.cssbox_thumb", function() {
                        var datasrc = $(this).parent().find("img.img_full").attr("data-src");
                        $(this).parent().find("img.img_full").attr("src",datasrc);
                        scale_val = 0;
                });
        }
        // Rotate on click (delegated event handler)
        function setimgsize(){
                if ( deg == 0 )                 { img_w = img_w0; img_h = img_h0; img_width  = img_width0; img_height = img_height0; }
                if ( deg == 90 || deg == -90 )  { img_h = img_w0; img_w = img_h0; img_height = img_width0; img_width  = img_height0; }
                if ( deg == 180 || deg == -180) { img_w = img_w0; img_h = img_h0; img_width  = img_width0; img_height = img_height0; }
                if ( deg == 270 || deg == -270) { img_h = img_w0; img_w = img_h0; img_height = img_width0; img_width  = img_height0; }
        }
        // function to insert image row if applicable
        function insertImgRow2(a) {
                isimg = 0;
                href = a.children[1].children[0].href;
                hrefsplit = href.split(".");
                fileExt = hrefsplit[hrefsplit.length - 1].toLowerCase();

                for (var i = 0; i < imgformats.length; i++) {
                        if (fileExt == imgformats[i].toLowerCase()) {
                                isimg = 1;
                                break;
                        }
                }
                if (isimg == 1){                       
                        href_full = href.split("/").reverse()[0] 
                        href_thumb = ".thumbs/" + href_full;
                        n_files = n_files + 1;
                        var thumb_src, img_href;
                        imgiter_prev = imgiter - 1;
                        imgiter_next = imgiter + 1;
                        if (imgiter_prev == -1){
                                imgiter_prev = "#";
                        } else{
                                imgiter_prev = "#image" + imgiter_prev;
                        }                        
                        
                        a.children[1].style.backgroundColor = "#202020";                        
                        if (fileExt == "pdf" || fileExt == "doc" || fileExt == "ppt" || fileExt == "xls" || fileExt == "txt" || fileExt == "docx" || fileExt == "pptx" || fileExt == "xlsx" || fileExt == "ppsx" || fileExt == "pps" || fileExt == "odt" ) {
                                img_href = href_thumb;
                        } else {
                                img_href = href_full;
                        }
                        if ( n_files < 6 ) {
                                thumb_src = "src";
                        } else {
                                thumb_src = "data-src";
                        } 
                        var irow = document.createElement("tr");
                        irow.className = "insert"
                        irow.innerHTML = '<td></td><td class="img" colspan="3"><div class="cssbox"><a id="image' + imgiter + '" href="#image' + imgiter + '"><img class="cssbox_thumb lazy" ' + thumb_src + '="' + href_thumb + '" alt=""/><span class="cssbox_full"><img class="img_full" style="width:' + img_width + '; height:' + img_height + '; max-width:' + img_w + ';max-height:' + img_h + ';object-fit: contain" data-src="' + img_href + '"/></span></a><a class="cssbox_close" href="#void"></a><a class="cssbox_prev" href="' + imgiter_prev + '">&lt;</a><a class="cssbox_next" href="#image' + imgiter_next + '">&gt;</a><a class="cssbox_title" href=' + href_full + '>' + decodeURI(href_full) + '</a><a class="cssbox_rotate-right"><img src="/cloud/.icons/object-rotate-right.png"/></a><a class="cssbox_rotate-left"><img src="/cloud/.icons/object-rotate-left.png"/></a><a class="cssbox_rotate-reset">0°</a><a class="cssbox_zoomin"><img src="/cloud/.icons/gtk-zoom-out.png"/></a></div></td>';
                        a.parentNode.insertBefore(irow,a.nextSibling);
                        imgiter = imgiter + 1;                        
                }
                isimg = 0;      
        }   
        function startsearch() {
                var target = $('#searchBox').val().replace(/ /g,"%20");
                if (target[0] == "^" && target[target.length-1] == "$" ) {
                        filter(target.substring(1,target.length-1));        
                } else if (target[0] == "^") {
                        filter(target.substring(1,target.length) + "*"); 
                } else if (target[target.length-1] == "$") {
                        filter("*" + target.substring(0,target.length-1)); 
                        
                } else {
                        filter("*" + target + "*");                
                }
        }
        // delay instant search on input (https://stackoverflow.com/a/7849308)
        var delayTimer;
        function doSearch() {
                    clearTimeout(delayTimer);
                    delayTimer = setTimeout(function() {
                            startsearch();
                    }, 900); // Will do the ajax stuff after 1000 ms, or 1 s
        }
        // Instant search.
        function filter(target){
                // search dirs (always display parent-dir "../")
                $("a.high4").each(function(){
                        href = $(this).attr('href');
                        if (matchRuleExpl(href.toLowerCase(), target.toLowerCase())){
                                n_dirs = n_dirs + 1;
                                if ( n_dirs % 2 == 0 ) { 
                                        $(this).parent().parent().css("background-color", "black").show().addClass("found");
                                } else { 
                                        $(this).parent().parent().css("background-color", "#202020").show().addClass("found");
                                }
                        } else {
                                $(this).parent().parent().hide().removeClass("found");
                        }
                });
                // search files in list mode
                if (x == 0){           
                        $("a.high5").each(function(){
                                href = $(this).attr('href');
                                if (matchRuleExpl(href.toLowerCase(), target.toLowerCase())) {
                                        n_files = n_files + 1;
                                        cum_size = cum_size + getsize($(this).parent().next().children().eq(0).text());
                                        if ( n_files % 2 == 0 ) { 
                                                $(this).parent().parent().css("background-color", "black").show().addClass("found");
                                        } else { 
                                                $(this).parent().parent().css("background-color", "#202020").show().addClass("found");
                                        }
                                } else {
                                        $(this).parent().parent().hide().removeClass("found");
                                }
                        });
                // search files in image mode
                } else {
                        var obj;
                        var imgiter_prev;
                        var imgiter_next;
                        $("a.high5").each(function(){
                                href = $(this).attr('href');
                                hrefsplit = href.split(".");
								fileExt = hrefsplit[hrefsplit.length - 1].toLowerCase();
								for (var i = 0; i < imgformats.length; i++) {
									if (fileExt == imgformats[i].toLowerCase()) {
																isimg = 1;
																break;
									}
                                }
                                if (isimg == 1){
                                        href_thumb = ".thumbs/" + href;
                                        href_full = href.split("/").reverse()[0]                                      
                                        obj = $(this).parent().parent().next().children("td.img").children("div").children("a").eq(0); //this is the inserted row, it is the first anchor in the cssbox div insert
                                        if (matchRuleExpl(href.toLowerCase(), target.toLowerCase())) {
                                                n_files = n_files + 1;
                                                cum_size = cum_size + getsize($(this).parent().next().children().eq(0).text());
                                                imgiter_prev = imgiter - 1;
                                                imgiter_next = imgiter + 1;                                         
                                                $(this).parent().parent().show().next().show().addClass("found");  
                                                if ( n_files < 6 ) {
                                                        obj.children("img.cssbox_thumb").attr("src", href_thumb);
                                                } else {
                                                        obj.children("img.cssbox_thumb").attr("data-src", href_thumb);
                                                }
                                                if (fileExt == "pdf" || fileExt == "doc" || fileExt == "ppt" || fileExt == "xls" || fileExt == "txt" || fileExt == "docx" || fileExt == "pptx" || fileExt == "xlsx" || fileExt == "ppsx" || fileExt == "pps" || fileExt == "odt" ) {
                                                        obj.children("span.cssbox_full").children("img.img_full").attr("data-src", href_thumb);
                                                } else { 
                                                        obj.children("span.cssbox_full").children("img.img_full").attr("data-src", href_full);
                                                }
                                                obj.attr("id", "image" + imgiter).attr("href", "#image" + imgiter);
                                                if (imgiter_prev == -1) {
                                                        obj.siblings("a.cssbox_prev").attr("href", "#");
                                                } else{
                                                        obj.siblings("a.cssbox_prev").attr("href", "#image" + imgiter_prev);
                                                }
                                                obj.siblings("a.cssbox_next").attr("href", "#image" + imgiter_next);                                                                                              
                                                lastobj = obj;
                                                imgiter = imgiter + 1;                                               
                                        } else {
                                                $(this).parent().parent().hide().next().hide().removeClass("found");
                                                obj.children("img.cssbox_thumb").removeAttr("src");
                                                obj.children("span.cssbox_full").children("img.img_full").removeAttr("src");
                                                obj.removeAttr("id").removeAttr("href");
                                                obj.siblings("a.cssbox_prev").removeAttr("href");
                                                obj.siblings("a.cssbox_next").removeAttr("href");                                                  
                                        }
                                } else{
                                        if (matchRuleExpl(href.toLowerCase(), target.toLowerCase())) {
                                                n_files = n_files + 1;
                                                cum_size = cum_size + getsize($(this).parent().next().children().eq(0).text());
                                                if ( n_files % 2 == 0 ) { 
                                                        $(this).parent().parent().css("background-color", "black").show().addClass("found");
                                                } else { 
                                                        $(this).parent().parent().css("background-color", "#202020").show().addClass("found");
                                                }
                                        } else {
                                                $(this).parent().parent().hide().removeClass("found");
                                        }    
                                }
                                isimg = 0;
                        });
                        if (imgiter > 0){
                                lastobj.siblings("a.cssbox_next").attr("href", "#");
                        }
                        imgiter = 0;
                        yall();
                }                
                document.getElementById("dirinfo").innerHTML = "dirs:" + n_dirs + "|files:" + n_files + "|" + get_cumsize(cum_size);
                n_files = 0;
                n_dirs = 0;
                cum_size = 0;
        }                      
        //END FUNCTION DEFS

// build document
$(document).ready(function(){
	    // make table visible
	    document.getElementsByClassName("listtable")[0].style.display = "table";
	    // calculate total size
        var slides = document.getElementsByClassName("high6");
        for(var i = 0; i < slides.length; i++)
        {
                cum_size  = cum_size  + getsize(slides[i].innerHTML);
        }
        $('#dirinfo').html($('#dirinfo').html() + "|" + get_cumsize(cum_size));
        cum_size  = 0;
        // build image mode
        if (x == 1){
                for (var i = 0, o = document.getElementsByClassName("row"), len = o.length;  i < len; i++) {
                        insertImgRow2(o[i]);
                }
                imgiter = 0;
                n_files = 0;
                imgview();
        }
        // switch between listing modes
        $("#mode").on('click',function(){
                x = (x+1)%2;
                if (x == 1){
                        document.getElementById("mode").src="/cloud/.icons/view-list-icons.png";
                        for (var i = 0, o = document.getElementsByClassName("row"), len = o.length;  i < len; i++) {
                                insertImgRow2(o[i]);
                        }         
                        imgiter = 0;
                        n_files = 0;
                        yall();                        
                        imgview();
                } else {
                        document.getElementById("mode").src="/cloud/.icons/view-list-compact.png";                        
                        for (var j = 0, o = document.querySelectorAll(".insert"), len = o.length;  j < len; j++) {
                                o[j].previousElementSibling.style.backgroundColor = "";
                                o[j].previousElementSibling.children[1].style.backgroundColor = "";
                                o[j].remove();
                        }
                }  
                if ($('#searchBox').val()){
                        startsearch();
                }     
        });        
        // clear searchbox	
        $("#searchBox").val('');		
        // Run when text is entered in the search box.
        $('#custom-search-form').on('input',function(e){
                e.preventDefault();
                doSearch(); // delays instant search
        });
        // Runs when clear button is hit.
        $("#searchclear").click(function(){
                $("#searchBox").val('');
                filter('*');                                
        });
        //Display date
        document.getElementById("date").innerHTML = Date();
});
