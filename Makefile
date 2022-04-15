MANUAL := SpaceCubics_OBC_FPGA_Technical_Reference_Manual_revx

all: ${MANUAL}.docx

${MANUAL}.docx: technical_reference_manual.org template/sc_pandoc_trm_reference.docx images/*.png
	pandoc --reference-doc template/sc_pandoc_trm_reference.docx $< -o $@

clean:
	${RM} *.docx *.pdf
