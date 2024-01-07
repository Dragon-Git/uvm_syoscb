<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT file for transforming scoreboard XML dumps to dot-format (GraphML) -->
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<xsl:template match="/scb"> <!-- Start matching at root of document -->
digraph G { ranksep=2;
  <!-- Create scoreboard node as root -->
  <xsl:call-template name="genPath" /> [label="Scoreboard: <xsl:value-of select="@name" />"];

  <!-- CREATE NODES -->
  <!-- Create queue nodes -->
  <xsl:apply-templates select="queues/queue" />

  <!-- Create top level item nodes -->
  <xsl:apply-templates select="//item" />

  <!-- Create all objects + content -->
  <xsl:apply-templates select="//members" />

  <!-- CREATE LINKS -->
  <!-- Links from SCB to all queue elements -->
  <xsl:call-template name="genPath" /> -> {<xsl:for-each select="queues/queue"><xsl:call-template name="genPath" />:n<xsl:text> </xsl:text></xsl:for-each>};

  <!-- Links from queue elements to item header -->
  <xsl:call-template name="queue-item-links" />

  <!-- Links from item headers to their item -->
  <xsl:call-template name="item-object-links" />

  <!-- Links from objects to nested objects -->
  <xsl:call-template name="object-object-links" />

  <!-- Links from arrays to nested objects -->
  <xsl:call-template name="array-object-links" />
}
</xsl:template>

<xsl:template match="queue">
  <xsl:call-template name="genPath" /> [label="<xsl:value-of select="@name" />"];
</xsl:template>

<xsl:template match="item">
  <xsl:call-template name="genPath" /> [shape=plaintext, label = &lt;
&lt;TABLE border="1" cellspacing="0" &gt;
  &lt;TR&gt;
    &lt;TD colspan="2"&gt;&lt;B&gt;<xsl:value-of select="@inst" />&lt;/B&gt;&lt;/TD&gt;
  &lt;/TR&gt;
  &lt;TR&gt;
    &lt;TD align="left"&gt;Producer&lt;/TD&gt;
    &lt;TD align="left"&gt;&lt;B&gt;<xsl:value-of select="@producer" />&lt;/B&gt;&lt;/TD&gt;
  &lt;/TR&gt;
  &lt;TR&gt;
    &lt;TD align="left"&gt;Queue index&lt;/TD&gt;
    &lt;TD align="left"&gt;&lt;B&gt;<xsl:value-of select="@queue_index" />&lt;/B&gt;&lt;/TD&gt;
  &lt;/TR&gt;
  &lt;TR&gt;
    &lt;TD align="left"&gt;Insertion index&lt;/TD&gt;
    &lt;TD align="left"&gt;&lt;B&gt;<xsl:value-of select="@insertion_index" />&lt;/B&gt;&lt;/TD&gt;
  &lt;/TR&gt;
&lt;/TABLE&gt;

  &gt;]
</xsl:template>

<xsl:template match="members">
  <xsl:call-template name="genPath" /> [shape=plaintext, label=&lt;
    &lt;TABLE border="1" cellborder="0" cellspacing="0"&gt;
      &lt;TR&gt;
      &lt;TD bgcolor="#00a0e4"&gt;&lt;B&gt; Name &lt;/B&gt;&lt;/TD&gt;
      &lt;TD bgcolor="#00a0e4"&gt;&lt;B&gt; Type &lt;/B&gt;&lt;/TD&gt;
      &lt;TD bgcolor="#00a0e4"&gt;&lt;B&gt; Size &lt;/B&gt;&lt;/TD&gt;
      &lt;TD bgcolor="#00a0e4"&gt;&lt;B&gt; Value &lt;/B&gt;&lt;/TD&gt;
      &lt;/TR&gt;
      <xsl:apply-templates /> <!-- Apply templates for member values, objects and arrays -->
    &lt;/TABLE&gt;
  &gt;]
</xsl:template>

<xsl:template match="member">
&lt;TR&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@name"/> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@type" /> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@size" /> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="current()" /> &lt;/TD&gt;
&lt;/TR&gt;
</xsl:template>

<xsl:template match="member_object">
&lt;TR&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@name"/> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@type" /> &lt;/TD&gt;
&lt;TD align="left"&gt; - &lt;/TD&gt;
&lt;TD align="left" port="<xsl:value-of select="@name"/>"&gt; <xsl:choose>
<xsl:when test="null">null
  </xsl:when>
  <xsl:otherwise>
  <xsl:value-of select="@name" />
  </xsl:otherwise>
  </xsl:choose>
 &lt;/TD&gt;
&lt;/TR&gt;
</xsl:template>

<xsl:template match="member_array">
&lt;TR&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@name" /> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@type" /> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:value-of select="@size" /> &lt;/TD&gt;
&lt;TD align="left"&gt; <xsl:choose>
  <xsl:when test="values">
    <xsl:apply-templates />
  </xsl:when>
  <xsl:otherwise>
[]
  </xsl:otherwise>
</xsl:choose>
&lt;/TD&gt;
&lt;/TR&gt;
</xsl:template>

<xsl:template match="values">
&lt;TABLE border="1" cellborder="0" cellspacing="0"&gt;
  <xsl:apply-templates /> <!-- Applies to value elements -->
&lt;/TABLE&gt;
</xsl:template>

<xsl:template match="value">
  &lt;TR&gt;
    &lt;TD align="left"&gt;<xsl:value-of select="node()/@name" /> &lt;/TD&gt;
    &lt;TD align="left" port="<xsl:value-of select="../../@name" />_<xsl:value-of select="translate(node()/@name, '[]', '')" />"&gt;<xsl:value-of select="node()/@type" />&lt;/TD&gt;
    <!-- port name is <object_name>:<object_name>_<array_index>, using translate() to strip out [] tokens from array index-->
  &lt;/TR&gt;
</xsl:template>


<xsl:template name="queue-item-links">
  <xsl:for-each select="//queue">
    <xsl:call-template name="genPath" /> -> {<xsl:for-each select="items/item"><xsl:call-template name="genPath" /><xsl:text> </xsl:text></xsl:for-each>};
  </xsl:for-each>
</xsl:template>

<xsl:template name="item-object-links">
  <xsl:for-each select="//item">
    <xsl:call-template name="genPath" /> -> {<xsl:for-each select="member_object/members"><xsl:call-template name="genPath" /><xsl:text> </xsl:text></xsl:for-each>};
  </xsl:for-each>
</xsl:template>

<xsl:template name="object-object-links">
  <xsl:for-each select="//member_object/members">
    <xsl:variable name="obj_path" >
      <xsl:call-template name="genPath" />
    </xsl:variable>
    <xsl:for-each select="member_object/members">
      <xsl:value-of select="$obj_path" />:<xsl:value-of select="../@name" /> -> <xsl:call-template name="genPath" /><xsl:text>:n&#10;</xsl:text> [label="<xsl:value-of select="../@name" />"]
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>

<xsl:template name="array-object-links">
  <xsl:for-each select="//member_object/members" >
    <xsl:variable name="obj_path" >
      <xsl:call-template name="genPath" />
    </xsl:variable>
    <xsl:for-each select="member_array/values">
      <xsl:for-each select="value/member_object/members">
        <xsl:value-of select="$obj_path" />:<xsl:value-of select="../../../../@name" />_<xsl:value-of select="translate(../@name, '[]', '')" />:e -> <xsl:call-template name="genPath" /><xsl:text>:n&#10;</xsl:text> [label="<xsl:value-of select="../@name" />"]
      </xsl:for-each>
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>

<xsl:template name="genPath">
  <xsl:param name="prevPath"/>
  <xsl:variable name="currPath" select="concat('/',name(),'[',
    count(preceding-sibling::*[name() = name(current())])+1,']',$prevPath)"/>
  <xsl:for-each select="parent::*">
    <xsl:call-template name="genPath">
      <xsl:with-param name="prevPath" select="$currPath"/>
    </xsl:call-template>
  </xsl:for-each>
  <xsl:if test="not(parent::*)">
    <xsl:value-of select="substring(translate($currPath, '/[]', '_'), 2)"/>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>