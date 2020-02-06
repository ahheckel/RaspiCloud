# from author TwistedInteractive ; Get File Extension V 1.0; released on 23. Sept. 2011; see https://www.getsymphony.com/download/xslt-utilities/view/77812/
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template name="get-file-extension">
       <xsl:param name="path" />
       <xsl:choose>
         <xsl:when test="contains( $path, '/' )">
           <xsl:call-template name="get-file-extension">
             <xsl:with-param name="path" select="substring-after($path, '/')" />
           </xsl:call-template>
         </xsl:when>
         <xsl:when test="contains( $path, '.' )">
           <xsl:call-template name="TEMP">
             <xsl:with-param name="x" select="substring-after($path, '.')" />
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:text>No extension</xsl:text>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:template>
    <xsl:template name="TEMP">
       <xsl:param name="x" />       
       <xsl:choose>
         <xsl:when test="contains($x, '.')">
           <xsl:call-template name="TEMP">
             <xsl:with-param name="x" select="substring-after($x, '.')" />
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$x" />
         </xsl:otherwise>
       </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
