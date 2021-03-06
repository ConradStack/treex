<?xml version="1.0"?>
<pml_schema version="1.1"
  xmlns="http://ufal.mff.cuni.cz/pdt/pml/schema/">
  <description>Example of dependency tree annotation</description>
  <root name="annotation">
    <structure>
      <member name="meta" type="meta.type"/>
      <member name="trees" required="1" role="#TREES">
	  <list type="node.type" ordered="1"/>
      </member>
    </structure>
  </root>
  <type name="meta.type">
    <structure>
      <member name="annotator"><cdata format="any"/></member>
      <member name="datetime"><cdata format="any"/></member>
    </structure>
  </type>
  <type name="node.type">
    <structure role="#NODE">
      <member name="word_ref" as_attribute="1" required="1" role="#ORDER">
        <cdata format="nonNegativeInteger"/>
      </member>
      <member name="form" required="1">
        <cdata format="any"/>
      </member>
      <member name="lemma" required="1">
        <cdata format="any"/>
      </member>
      <member name="ana" required="0">
        <cdata format="any"/>
      </member>
      <member name="syfun" required="0">
        <cdata format="any"/>
      </member>
      <member name="role" required="0">
        <cdata format="any"/>
      </member>
      <member name="governs" role="#CHILDNODES" required="0">
        <list type="node.type" ordered="0"/>
      </member>
    </structure>
  </type>
</pml_schema>
