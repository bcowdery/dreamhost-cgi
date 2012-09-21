<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:template match="/"> 
	<rss version="2.0">
	  <channel>
		<title><xsl:value-of select="/rss/channel/title"/></title>
		<description/>	
		<xsl:apply-templates select="/rss/channel/item"/>
	  </channel>
	</rss>
  </xsl:template>
    
  <xsl:template match="item">	
	<item>
      <title><xsl:value-of select="title"/></title>
      <description><xsl:value-of select="description"/></description>
	  <!-- todo: replace 'at' with 'and', remove words like Ramp -->	
	  <link>https://maps.google.ca/maps?q=<xsl:value-of select="title"/>, Calgary, AB</link>
      <pubDate><xsl:value-of select="pubDate"/></pubDate>
	</item>  
  </xsl:template>
  
</xsl:stylesheet>