<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT file for transforming scoreboard XML dumps to HTML -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" indent="yes"/>
<xsl:template match="/"> <!-- Start matching at root of the document -->
  <html>
  <head>
    <title>Syoscb Scoreboard Dump</title>
    <style>
      table, th, td {
        border-collapse: collapse;
      }
      .tr-header {
        background-color: #00a0e4;
        border-left: 2px solid;
        border-right: 2px solid;
        border-bottom: 2px solid;
        text-align: left;
      }

      td {
        vertical-align: top;
      }

      th {
        padding-right: 1ex;
      }

      .nested-table > tbody > .tr-header {
        border-left: none;
        border-right: none;
      }

      .nested-table {
        width: 100%;
      }

      .syoscb-item {
        width: 100%;
      }

      .syoscb-item-details {
        width: 100%;
      }

      .syoscb-item-wrapper-td {
        vertical-align: top;
        border-right: 2px solid;
        border-left: 2px solid;
      }

      .syoscb-item {
        border-bottom: 2px solid;
        margin-bottom: 1ex;
      }

      #main-table {
        border-bottom: 2px solid;
        border-top: 2px solid;
      }

      details > table {
        margin-top: 0.7ex;
        border-top: 2px solid;
        border-bottom: 2px solid;
      }

      .nested-table > tbody > tr > td {
        padding-right: 1ex;
      }
    </style>
  </head>
  <body>
    <img src="https://syosil.com/images/logo.png" style="width: 15%;" alt="SyoSil Logo"/>
    <h1>Scoreboard <xsl:value-of select="scb/@name" /> </h1>
    <p>To expand nested items and arrays, click the triangle or name of the object
    <details>
      <summary>Like this</summary>
      Hello, world
    </details></p>
  <table id="main-table">

  <!-- Create header row with all queue names -->
  <tr class="tr-header">
    <xsl:for-each select="scb/queues/queue">
      <th><h3> Queue <xsl:value-of select="@name" /> </h3></th>
    </xsl:for-each>
  </tr>
  <tr>
    <xsl:for-each select="scb/queues/queue" >
        <xsl:apply-templates /> <!-- Applies <items> template -->
    </xsl:for-each>
  </tr>
  </table>
  </body>
  </html>
</xsl:template>

<xsl:template match="items"> <!-- Creates <td> wrapping all syoscb-items in a queue, invokes <item> -->
<td class="syoscb-item-wrapper-td">
  <table class="syoscb-item-wrapper">
  <xsl:apply-templates />
  </table>
</td>
</xsl:template>

<xsl:template match="item"> <!-- Top-level table containing the cl_syoscb_item -->
<tr><td>
    <table class="syoscb-item">
      <tr>
        <td colspan="4">
          <table class="syoscb-item-details">
            <tr>
              <td><b><xsl:value-of select="@inst" /></b> </td> <td> Producer: <b><xsl:value-of select="@producer"/></b></td>
            </tr>
            <tr>
              <td>Queue index: <b><xsl:value-of select="@queue_index"/></b> </td><td>Insertion index: <b><xsl:value-of select="@insertion_index"/></b></td>
            </tr>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <xsl:apply-templates select="member_object/members" />
        </td>
      </tr>
    </table>
  </td></tr>
</xsl:template>

<xsl:template match="members"> <!-- Member values of object -->
<table class="member-table-contents nested-table">
  <tr class="tr-header">
    <th>Name</th>
    <th>Type</th>
    <th>Size</th>
    <th>Value</th>
  </tr>
  <xsl:apply-templates />
  </table>
</xsl:template>

<xsl:template match="member">
  <tr>
  <td><xsl:value-of select="@name" /></td>
  <td><xsl:value-of select="@type" /></td>
  <td><xsl:value-of select="@size" /></td>
  <td><xsl:value-of select="current()" /></td>
</tr>
</xsl:template>

<xsl:template match="member_object"> <!-- Member object inside of another object -->
<tr>
  <td><xsl:value-of select="@name" /></td>
  <td><xsl:value-of select="@type" /></td>
  <td>-</td>
  <td>
    <xsl:choose>
      <xsl:when test="null">
        &lt;null&gt;
      </xsl:when>
      <xsl:otherwise>
        <details>
          <summary><xsl:value-of select="@name" /></summary>
            <xsl:apply-templates /> <!-- Applies <members> template -->
        </details>
      </xsl:otherwise>
    </xsl:choose>
  </td>
</tr>
</xsl:template>

<xsl:template match="member_array"> <!-- Array inside of an object -->
  <tr>
    <td><xsl:value-of select="@name" /></td>
    <td><xsl:value-of select="@type" /></td>
    <td><xsl:value-of select="@size" /></td>
    <td>
      <xsl:choose>
        <xsl:when test="values">
          <details>
            <summary><xsl:value-of select="@name" /></summary>
            <table class="array-table nested-table" >
              <xsl:apply-templates select="values/value" />
            </table>
          </details>
        </xsl:when>
        <xsl:otherwise>
          []
        </xsl:otherwise>
      </xsl:choose>

    </td>
  </tr>
</xsl:template>

<xsl:template match="value/member"> <!-- Primitive member inside of array -->
<tr>
  <td><xsl:value-of select="@name" /></td>
  <td><xsl:value-of select="current()" /></td>
</tr>
</xsl:template>

<xsl:template match="value/member_object"> <!-- Member object inside of array -->
<tr>
  <td><xsl:value-of select="@name" /></td>
  <td>
    <xsl:choose>
      <xsl:when test="null">
        &lt;null&gt;
      </xsl:when>
      <xsl:otherwise>
        <details>
          <summary><xsl:value-of select="@name" /> (<b><xsl:value-of select="@type"/>)</b></summary>
          <xsl:apply-templates />
        </details>
      </xsl:otherwise>
    </xsl:choose>
  </td>
</tr>
</xsl:template>

</xsl:stylesheet>