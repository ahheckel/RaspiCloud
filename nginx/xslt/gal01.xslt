<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="utf-8" indent="yes" />
<xsl:include href="get-file-extension.xsl"/>    
    <xsl:template match="/">                  
    <html>
    <!-- ENTRY03 -->
    <link href="/cloud/.gal.css" rel="stylesheet" type="text/css" media="all"/>
        <body>  
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=0.1" />
            <script src="/cloud/.yall.min.js"></script>
        </head>
        
        <!-- TOP HEADER -->
        <table class="listtable">
        <colgroup>
                <col class="col-icon"></col>
                <col class="col-name"></col>
                <col class="col-size"></col>
                <col class="col-date"></col>
        </colgroup>  
        <tr class="black" id="menurow">
            <td colspan="2">
                <h1 id="cwd"></h1>  
            </td>
            <td></td>
            <td> 
                <div id="dropdown" style="float:right;">
                    <button class="dropbtn"></button>
                    <div class="dropdown-content">
                        <a href="http://www.google.com">Google</a>
                        <p style="border-bottom: 4px solid #aa0"></p>
                        <a href="/cloud/User1/tmp">Cloud User1</a>
                        <a href="/cloud/User2/tmp">Cloud User2</a>
                        <a href="/cloud/User3/tmp">Cloud user3</a>
                        <p style="border-bottom: 4px solid #aa0"></p>
                        <a href="/cloud/.gps">GPS</a>                        
                    </div>
                </div> 
            </td>
        </tr>        
        <tr class="black">
            <td></td>
            <td colspan="3">
                <h2 id="parentdir"><div id="dirinfo">dirs:<xsl:value-of select="count(//directory)"/>|files:<xsl:value-of select="count(//file)"/></div></h2>
            </td>   
        </tr>        
        <tr class="black">
            <td id="searchclear"><img src="/cloud/.icons/searchcancel.png"/></td>
            <td style="padding-left:0px">
                <form id="custom-search-form" autocomplete="off">
                    <div>
                        <input id="searchBox" placeholder="Search" type="search" class="form-control"/> 
                    </div>
                </form>
            </td>
            <td colspan="2"></td>
        </tr>

        <!-- HEADER -->
        <tr class="black">
            <td></td>
            <td colspan="3" class="bar"></td>
        </tr>
        <tr class="head">
            <td class="icon"><img id="mode" src=""/></td>
            <!-- ENTRY01 -->
            <td class="header" align="left"><a class="high3" href="/cloud/" id="sortname" style="color:#fff">Name</a></td>
            <td class="header" align="left"><a class="high3" href="/cloud/" id="sortsize">Size</a></td>
            <td class="header" align="left"><a class="high3" href="/cloud/" id="sortdate">Date</a></td>
        </tr>
        <script src="/cloud/.jquery.min.js"></script>
        <!-- ENTRY04 -->
        <script src="/cloud/.gal.js"></script>
        
        <!-- DIR LISTING -->
        <td class="icon"><a href="#"><img class="icon" src="/cloud/.icons/folder-home.png"/></a></td>
        <td colspan="3"><a class="high1" href="../">>../</a></td>        
        <xsl:for-each select="list/directory">
            <xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending"/>
                <xsl:variable name="name">
                    <xsl:value-of select="."/>
                </xsl:variable>
                <xsl:variable name="date">
                    <xsl:value-of select="substring(@mtime,9,2)"/>-<xsl:value-of select="substring(@mtime,6,2)"/>-<xsl:value-of select="substring(@mtime,1,4)"/><xsl:text> </xsl:text>
                    <xsl:value-of select="substring(@mtime,12,2)"/>:<xsl:value-of select="substring(@mtime,15,2)"/>
                </xsl:variable>
            <tr> 
                <td class="icon"><a href="#"><img class="icon" src="/cloud/.icons/folder-remote.png"/></a></td>
                <td><a class="high4" href="{$name}">><xsl:value-of select="."/></a></td>
                <td></td>
                <td><a class="high8" href="{$name}"><xsl:value-of select="$date"/></a></td>
            </tr>
        </xsl:for-each>
    
        <tr class="black">
            <td colspan="4" class="bar" style="border-top-width:0px"></td>
        </tr>
         
        <!-- FILE LISTING -->
        <xsl:for-each select="list/*">
        <!-- ENTRY02 -->
        <xsl:sort order="ascending" select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
            <xsl:if test="string-length(@size) &gt; 0">   
            <xsl:variable name="name">
                <xsl:value-of select="."/>
            </xsl:variable>
            <xsl:variable name="size">
                <xsl:if test="number(@size) &gt;= 0">
                    <xsl:choose>
                        <xsl:when test="round(@size div 1024) &lt; 1"><xsl:value-of select="@size" />B</xsl:when>
                        <xsl:when test="round(@size div 1048576) &lt; 1"><xsl:value-of select="format-number((@size div 1024), '0.0')" />K</xsl:when>
                        <xsl:when test="round(@size div 1073741824) &lt; 1"><xsl:value-of select="format-number((@size div 1048576), '0.0')" />M</xsl:when>
                        <xsl:when test="round(@size div 1099511627776) &lt; 1"><xsl:value-of select="format-number((@size div 1073741824), '0.00')" />G</xsl:when>
                        <xsl:otherwise><xsl:value-of select="format-number((@size div 1099511627776), '0.00')" />T</xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="date">
                <xsl:value-of select="substring(@mtime,9,2)"/>-<xsl:value-of select="substring(@mtime,6,2)"/>-<xsl:value-of select="substring(@mtime,1,4)"/><xsl:text> </xsl:text>
                <xsl:value-of select="substring(@mtime,12,2)"/>:<xsl:value-of select="substring(@mtime,15,2)"/>
            </xsl:variable>
        <tr class="row">            
            <xsl:variable name="ext">
                <xsl:call-template name="get-file-extension">
                    <xsl:with-param name="path" select="translate($name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
                </xsl:call-template>
            </xsl:variable>

            <td class="icon"><a href="#"><img class="icon" src="/cloud/.icons/{$ext}.png" alt="." /></a></td>
            <td><a class="high5" href="{$name}"><xsl:value-of select="."/></a></td>
            <td align="right"><a class="high6" href="{$name}"><xsl:value-of select="$size"/></a></td>
            <td><a class="high7" href="{$name}"><xsl:value-of select="$date"/></a></td>
        </tr>
        </xsl:if>
        </xsl:for-each>
        </table>
        <hr style="align:center;margin-top:100px;margin-bottom:20px;width:10%;height:4px;border-width:6px;color:#aaa"/>
        <p align="center" id="date" style="color:#aaa;font-size:30px">LOADING...</p>
        <p>.</p>
        <p>.</p>
        <p>.</p>
    </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
